#!/usr/bin/env python3
"""Bounded sparse native stills from real mapped-input Salmon Creek route."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import struct
import subprocess
import tempfile
import time

import salmon_opening_probe as opening

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = Path.home() / ".hermes/cache/scratch"
FRAMES = (0, 75, 105, 132, 163, 300, 429, 462, 899)
ACTIVE_FRAMES = (0, 75, 105, 145, 175, 204, 300, 520, 899)
ALLOWED = opening.ALLOWED | {"ERROR: Can't create shader cache folder, no shader caching will happen: user://"}


def identity():
    source = opening.source_identity()
    for name in ("tests/integration/salmon_creek_first_30_route_test.gd", "tools/evidence/salmon_first_30_stills.py"):
        source["files"][name] = opening.digest(ROOT / name)
    source["content_sha256"] = hashlib.sha256(json.dumps(source["files"], sort_keys=True).encode()).hexdigest()
    return source


def guard(temporary, destination, started):
    if time.monotonic() - started > 120:
        raise ValueError("120-second independent wall guard")
    files = [p for p in temporary.rglob("*") if p.is_file()]
    if sum(p.stat().st_size for p in files) > 16 * 1024**2:
        raise ValueError("16-MiB independent byte guard")
    if len(list((temporary / "frames").glob("frame_*.png"))) > len(FRAMES):
        raise ValueError("nine-frame independent count guard")
    if min(shutil.disk_usage(temporary).free, shutil.disk_usage(destination.parent).free) < 6 * 1024**3:
        raise ValueError("6-GiB independent free-space guard")


def stop_group(process):
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            break
        if sig == signal.SIGTERM:
            time.sleep(0.2)
    process.wait(timeout=5)


def check_engine(log):
    counts = {}
    for line in log.splitlines():
        line = line.strip()
        if line in ALLOWED:
            counts[line] = counts.get(line, 0) + 1
            if counts[line] > 1:
                raise ValueError("repeated known engine diagnostic: " + line)
        elif any(token in line for token in ("ERROR:", "SCRIPT ERROR", "leaked at exit", "still in use at exit", "orphan")):
            raise ValueError("unexpected engine diagnostic: " + line)
    if "SALMON FIRST 30 ROUTE: PASS" not in log:
        raise ValueError("missing route PASS sentinel")
    return counts


def validate(data, frames, size, route="retry"):
    if data["viewport"] != list(size) or data["process"] != 900 or abs(data["physics"] - 1800) > 2:
        raise ValueError("wrong viewport or simulation duration")
    if data["route"] != route or len(data["shot"]) != (2 if route == "active" else 1) or not data["warning"] or not data["attack"] or data["attack"][0] <= data["warning"][0]:
        raise ValueError("mapped shot/contact missing")
    if not 0 <= data["gate"] <= data["shed"] < 900 or not data["death"] < data["recovered"] < 900:
        raise ValueError("route or Retry missing")
    selected_frames = ACTIVE_FRAMES if route == "active" else FRAMES
    if [sample["frame"] for sample in data["frames"]] != list(selected_frames) or len(frames) != len(selected_frames):
        raise ValueError("missing or extra sampled frames")
    if route == "active" and (data["mower_warning"][0] >= 98 or data["mower_attack"][0] <= 118 or data["mower_attack_x"][0] - data["mower_warning_x"][0] < 1.5 or data["lateral"] < 2 or data["health_shed"] < 100 or data["death"] < 500):
        raise ValueError("active route lacks mapped field charge avoidance or shed combat")
    expected_zones = (("forbidden_field",) * 4 + ("equipment_shed",) * 4 + ("forbidden_field",)) if route == "active" else (("forbidden_field",) * 4 + ("equipment_shed",) * 3 + ("forbidden_field",) * 2)
    for sample, frame in zip(data["frames"], frames):
        raw = frame.read_bytes()
        if raw[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", raw[16:24]) != size:
            raise ValueError("invalid rendered PNG dimensions")
        if frame.name != "frame_%04d.png" % sample["frame"] or sample["sha256"] != opening.digest(frame):
            raise ValueError("sample hash/name mismatch")
        if abs(sample["process_frame"] - (sample["frame"] + 1)) > 1:
            raise ValueError("render sample not bound to route frame")
    if tuple(sample["zone"] for sample in data["frames"]) != expected_zones:
        raise ValueError("frame-bound zone transitions disagree with field, shed and Retry route")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--tablet", action="store_true")
    parser.add_argument("--route", choices=("retry", "active"), default="retry")
    args = parser.parse_args()
    destination = args.out.resolve()
    if destination.exists():
        raise ValueError("refusing to overwrite evidence")
    destination.parent.mkdir(parents=True, exist_ok=True)
    if shutil.disk_usage(destination.parent).free < 6 * 1024**3:
        raise ValueError("less than 6 GiB free")
    source = identity()
    size = (1024, 768) if args.tablet else (1280, 720)
    version = subprocess.check_output(["/opt/homebrew/bin/godot", "--version"], timeout=10).decode().strip()
    if not version.startswith("4.7."):
        raise ValueError("Godot 4.7 required")
    with tempfile.TemporaryDirectory(prefix="cobie-route-stills-", dir=SCRATCH) as path:
        temporary = Path(path)
        home = temporary / "home"
        frames_dir = temporary / "frames"
        home.mkdir()
        frames_dir.mkdir()
        env = dict(os.environ)
        env.pop("PYTHONPATH", None)
        env.pop("VIRTUAL_ENV", None)
        for key in ("HOME", "CFFIXED_USER_HOME", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            env[key] = str(home)
        env["COBIE_TEST_SAVE_ROOT"] = str(home / "saves")
        cmd = ["/opt/homebrew/bin/godot", "--path", str(ROOT), "--resolution", "%dx%d" % size,
               "--fixed-fps", "30", "--script", "res://tests/integration/salmon_creek_first_30_route_test.gd",
               "--", "--capture-dir=" + str(frames_dir), "--capture-size=%dx%d" % size,
               "--route=" + args.route]
        started = time.monotonic()
        process = None
        log = temporary / "engine.log"
        try:
            with log.open("w") as stream:
                process = subprocess.Popen(cmd, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
                last_count, last_progress = 0, started
                while process.poll() is None:
                    guard(temporary, destination, started)
                    count = len(list(frames_dir.glob("frame_*.png")))
                    if count != last_count:
                        last_count, last_progress = count, time.monotonic()
                    if time.monotonic() - last_progress > 45:
                        raise ValueError("45-second independent progress guard")
                    time.sleep(0.1)
            guard(temporary, destination, started)
            if process.returncode != 0:
                raise ValueError("Godot exit " + str(process.returncode))
            diagnostics = check_engine(log.read_text())
            data = json.loads((frames_dir / "captures.json").read_text())
            frames = sorted(frames_dir.glob("frame_*.png"))
            validate(data, frames, size, args.route)
            if identity() != source:
                raise ValueError("source changed during native capture")
            shutil.copytree(frames_dir, destination)
            shutil.copy2(log, destination / "engine.log")
            (destination / "source.json").write_text(json.dumps(source, indent=2) + "\n")
            receipt = {"status": "PASS", "kind": "sparse_native_input_route_stills", "route": args.route, "source_sha256": source["content_sha256"],
                       "source_head": source["head"], "viewport": list(size), "frames": list(ACTIVE_FRAMES if args.route == "active" else FRAMES),
                       "png_bytes": sum(p.stat().st_size for p in frames), "wall_seconds": time.monotonic() - started,
                       "engine_version": version, "known_engine_diagnostics": diagnostics,
                       "human_approval": False, "continuous_rendered_video": False, "movie_maker": False}
            (destination / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
            print(json.dumps(receipt, indent=2))
        except Exception:
            destination.mkdir(exist_ok=True)
            if log.exists():
                shutil.copy2(log, destination / "FAILED-engine.log")
            raise
        finally:
            if process is not None:
                stop_group(process)


if __name__ == "__main__":
    main()
