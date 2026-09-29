#!/usr/bin/env python3
"""Pinned, on-demand Godot MCP server and isolated synthetic smoke test."""
import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import socket
import struct
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
REVISION = "0854fee0974b615297cae52da8beb91d8a37e415"
CHECKOUT = Path.home() / ".codex/game-dev-tools/candidates/alexmeckes--godot-mcp"


def verified_checkout(checkout):
    def git(*args):
        return subprocess.check_output(["git", "-C", str(checkout), *args], text=True).strip()
    if git("rev-parse", "HEAD") != REVISION or git("status", "--porcelain"):
        raise RuntimeError("Godot MCP checkout must be clean at " + REVISION)
    if not (checkout / "dist/index.js").is_file():
        raise RuntimeError("Godot MCP build missing")
    if not (checkout / "node_modules/@modelcontextprotocol/sdk/package.json").is_file():
        raise RuntimeError("Run npm ci --ignore-scripts in the pinned checkout")
    return checkout.resolve()


def safe_env():
    allowed = {"PATH", "HOME", "USER", "LANG", "LC_ALL", "TERM", "SHELL", "TMPDIR"}
    return {key: value for key, value in os.environ.items() if key in allowed}


def scan_errors(log):
    bad = [line for line in log.splitlines() if any(token in line for token in (
        "SCRIPT ERROR", "ERROR:", "Parse Error", "ObjectDB instances leaked",
        "resources still in use", "Orphan StringName"))]
    if bad:
        raise RuntimeError("Engine log failed: " + "\n".join(bad[:20]))


def stop_owned(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGINT)
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def run_owned(command, env, log, timeout):
    process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
                               start_new_session=True)
    try:
        code = process.wait(timeout=timeout)
        if code:
            raise subprocess.CalledProcessError(code, command)
    finally:
        stop_owned(process)


def probe(checkout, output):
    output.mkdir(parents=True, exist_ok=False)
    with socket.socket() as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("127.0.0.1", 6550))  # Refuse to attach to somebody else's editor.
    if shutil.disk_usage(ROOT).free < 6 * 1024**3:
        raise RuntimeError("Insufficient scratch space; need 6 GiB free for this bounded probe")
    with tempfile.TemporaryDirectory(prefix="cobie-godot-mcp-") as scratch:
        project = Path(scratch) / "project"
        project.mkdir()
        home = Path(scratch) / "home"
        home.mkdir()
        env = safe_env()
        env.update(HOME=str(home), CFFIXED_USER_HOME=str(home),
                   XDG_DATA_HOME=str(home / "data"), XDG_CONFIG_HOME=str(home / "config"),
                   XDG_CACHE_HOME=str(home / "cache"))
        shutil.copytree(checkout / "addons/godot_ai_bridge", project / "addons/godot_ai_bridge")
        (project / "project.godot").write_text('''config_version=5
[application]
config/name="Cobie ENV2 Probe"
run/main_scene="res://probe.tscn"
[autoload]
GodotAIBridgeRuntime="*res://addons/godot_ai_bridge/runtime_bridge.gd"
[display]
window/size/viewport_width=640
window/size/viewport_height=360
[rendering]
renderer/rendering_method="gl_compatibility"
[editor_plugins]
enabled=PackedStringArray("res://addons/godot_ai_bridge/plugin.cfg")
''')
        (project / "probe.gd").write_text('''extends ColorRect
var taps: int = 0
func _ready() -> void:
    get_window().borderless = true
    get_window().size = Vector2i(640, 360)
    get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
    get_window().content_scale_size = Vector2i(640, 360)
    add_to_group("probe")
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        taps += 1
        color = Color(0.08, 0.32, 0.42)
''')
        (project / "probe.tscn").write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://probe.gd" id="1"]
[node name="Probe" type="ColorRect"]
offset_right = 640.0
offset_bottom = 360.0
color = Color(0.1, 0.15, 0.2, 1)
script = ExtResource("1")
[node name="Label" type="Label" parent="."]
offset_left = 32.0
offset_top = 100.0
offset_right = 610.0
offset_bottom = 240.0
theme_override_font_sizes/font_size = 28
text = "COBIE / TOOLCHAIN PROBE\nSynthetic fixture - not gameplay"
''')
        godot = shutil.which("godot")
        node = shutil.which("node")
        if not godot or not node:
            raise RuntimeError("Godot and Node must be on PATH")
        with (output / "import.log").open("w") as log:
            run_owned([godot, "--headless", "--path", str(project), "--editor", "--quit"],
                      env, log, 60)
        scan_errors((output / "import.log").read_text())
        with (output / "editor.log").open("w") as log:
            process = subprocess.Popen([godot, "--path", str(project), "--editor"],
                                       env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            try:
                deadline = time.monotonic() + 30
                while time.monotonic() < deadline:
                    if process.poll() is not None:
                        raise RuntimeError("Editor exited before ready")
                    if "Server started on port 6550" in (output / "editor.log").read_text():
                        break
                    time.sleep(0.2)
                else:
                    raise RuntimeError("Editor bridge readiness deadline exceeded")
                with (output / "client.log").open("w") as client_log:
                    run_owned([node, str(ROOT / "tools/godot_mcp_probe.mjs"), str(checkout),
                               str(project), str(output)], env, client_log, 70)
            finally:
                stop_owned(process)
        scan_errors((output / "editor.log").read_text())
        png = (output / "probe.png").read_bytes()
        if png[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", png[16:24]) != (640, 360):
            raise RuntimeError("Screenshot is not the requested 640x360 PNG")
    print(json.dumps({"status": "pass", "checkout_revision": REVISION, "output": str(output),
                      "evidence_class": "synthetic editor/runtime fixture; not game/device acceptance"}))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["serve", "probe"])
    parser.add_argument("--checkout", type=Path, default=CHECKOUT)
    parser.add_argument("--project", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    checkout = verified_checkout(args.checkout)
    if args.mode == "serve":
        project = args.project.resolve()
        if not (project / "project.godot").is_file():
            parser.error("--project must contain project.godot")
        node = shutil.which("node")
        if not node:
            parser.error("Node must be on PATH")
        os.execve(node, [node, str(checkout / "dist/index.js"), "--project", str(project)], safe_env())
    else:
        if args.output is None:
            parser.error("probe requires --output (new directory)")
        probe(checkout, args.output.resolve())


if __name__ == "__main__":
    main()
