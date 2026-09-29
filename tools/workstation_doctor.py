#!/usr/bin/env python3
"""Read-only workstation prerequisites; never claims a tested build or device."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
GIB = 1024 ** 3
REQUIRED_TEMPLATES = ('web_nothreads_debug.zip', 'web_nothreads_release.zip', 'macos.zip')


def template_version(version: str) -> str:
    match = re.fullmatch(r'(4\.7\.\d+)\.stable\.official(?:\.[A-Za-z0-9_-]+)*', version.strip())
    if not match:
        raise ValueError('Requires an official stable Godot 4.7 patch version')
    return match.group(1) + '.stable'


def template_checks(directory: Path, expected: str, ios: bool = False) -> list[dict]:
    rows = []
    try:
        valid_version = (directory / 'version.txt').read_text().strip() == expected
    except OSError:
        valid_version = False
    rows.append({'check': 'template version', 'status': 'PASS' if valid_version else 'FAIL', 'detail': str(directory)})
    for name in REQUIRED_TEMPLATES + (('ios.zip',) if ios else ()):
        path = directory / name
        try:
            with zipfile.ZipFile(path) as archive:
                valid = bool(archive.infolist()) and archive.testzip() is None
        except (OSError, zipfile.BadZipFile, RuntimeError):
            valid = False
        rows.append({'check': name, 'status': 'PASS' if valid else 'FAIL', 'detail': 'ZIP integrity only; fresh export required'})
    return rows


def space_status(free_bytes: int, require_headroom: bool) -> str:
    if free_bytes < 6 * GIB or (require_headroom and free_bytes < 20 * GIB):
        return 'FAIL'
    return 'WARN' if free_bytes < 20 * GIB else 'PASS'


def run(command: list[str]) -> tuple[int, str]:
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
        return result.returncode, (result.stdout + result.stderr).strip()
    except (OSError, subprocess.TimeoutExpired) as error:
        return 1, type(error).__name__


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--ios', action='store_true', help='Require iOS template and Apple SDK, not signing/device acceptance')
    parser.add_argument('--require-headroom', action='store_true', help='Fail below 20 GiB before expensive capture/parallel builds')
    args = parser.parse_args()
    rows = []
    def add(name: str, status: str, detail: str) -> None:
        rows.append({'check': name, 'status': status, 'detail': detail})
    godot = os.environ.get('GODOT_BIN') or shutil.which('godot')
    code, version = run([godot, '--version']) if godot else (1, 'Godot not found')
    try:
        expected = template_version(version) if code == 0 else ''
    except ValueError:
        expected = ''
    add('Godot', 'PASS' if expected else 'FAIL', version)
    if expected:
        if platform.system() == 'Darwin':
            base = Path.home() / 'Library/Application Support/Godot/export_templates'
        else:
            base = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'godot/export_templates'
        # Explicit override supports nonstandard installs without guessing.
        directory = Path(os.environ.get('GODOT_TEMPLATE_DIR', str(base / expected)))
        rows.extend(template_checks(directory, expected, args.ios))
    free = shutil.disk_usage(ROOT).free
    add('scratch headroom', space_status(free, args.require_headroom), f'{free / GIB:.2f} GiB free; 6 GiB minimum, 20 GiB recommended')
    project = (ROOT / 'project.godot').read_text()
    bridge = (ROOT / 'addons/godot_ai_bridge').exists() or any(token in project for token in ('GodotAIBridgeRuntime', 'godot_ai_bridge'))
    add('export bridge exclusion', 'FAIL' if bridge else 'PASS', 'Source boundary only; package inspection still required')
    for name in ('blender', 'ffmpeg', 'codex'):
        path = shutil.which(name)
        add(name, 'PASS' if path else 'WARN', path or 'Not on PATH; verify any application-only install separately')
    if args.ios:
        code, sdk = run(['xcrun', '--sdk', 'iphoneos', '--show-sdk-version'])
        add('iPhoneOS SDK', 'PASS' if code == 0 else 'FAIL', sdk)
        add('iOS delivery', 'WARN', 'Template/SDK are not an iOS preset, signed build, or physical-device result')
    add('optional editor MCPs', 'INFO', 'Run tools/game_dev_health.sh for the separate privileged-tool gate; missing MCPs do not block CLI work')
    failed = any(row['status'] == 'FAIL' for row in rows)
    report = {'status': 'FAIL' if failed else ('WARN' if any(row['status'] == 'WARN' for row in rows) else 'PASS'), 'scope': 'prerequisites, not release acceptance', 'checks': rows}
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        for row in rows:
            print(f"{row['status']:4} {row['check']}: {row['detail']}")
        print('WORKSTATION PREREQUISITES:', report['status'])
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
