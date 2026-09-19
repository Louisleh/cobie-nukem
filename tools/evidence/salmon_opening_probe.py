#!/usr/bin/env python3
"""Bounded, isolated non-Movie-Maker opening capture; no release acceptance."""
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

ROOT = Path(__file__).resolve().parents[2]
ALLOWED = {
    "ERROR: 1 shaders of type ParticlesShaderGLES3 were never freed",
    "ERROR: 1 RID allocations of type 'N5GLES36ShaderE' were leaked at exit.",
}


def check_log(text):
    counts = {}
    for line in text.splitlines():
        line = line.strip()
        if line in ALLOWED:
            counts[line] = counts.get(line, 0) + 1
            if counts[line] > 1:
                raise ValueError("repeated renderer teardown diagnostic")
        elif any(s in line for s in ("ERROR:", "SCRIPT ERROR", "leaked at exit", "still in use at exit", "orphan")):
            raise ValueError("engine failure: " + line)
    if "SALMON OPENING PROBE: COMPLETE" not in text:
        raise ValueError("missing completion sentinel")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_identity():
    paths = subprocess.check_output(["git", "ls-files", "-z", "scripts", "scenes", "resources", "assets", "project.godot"], cwd=ROOT).decode().split("\0")
    hashes = {p: digest(ROOT / p) for p in paths if p and (ROOT / p).is_file()}
    untracked = subprocess.check_output(["git", "ls-files", "--others", "--exclude-standard", "scripts", "scenes", "resources", "assets"], cwd=ROOT).decode().strip()
    if untracked:
        raise ValueError("untracked runtime dependencies must be staged before capture")
    for suffix in ("gd", "py"):
        name = "tools/evidence/salmon_opening_probe." + suffix
        hashes[name] = digest(ROOT / name)
    return {"head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT).decode().strip(),
            "content_sha256": hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest(),
            "files": hashes}


def validate_receipt(data, frames, seconds, expected_size, home):
    if data["frames"] != seconds * 30 or data["viewport"] != list(expected_size):
        raise ValueError("runtime duration or dimensions disagree")
    if data["movie_maker"] or data["teleports"] or data["direct_encounter_activation"]:
        raise ValueError("forbidden staging")
    for key in ("user_data_dir", "save_directory"):
        if not Path(data[key]).resolve().is_relative_to(home.resolve()):
            raise ValueError("user state escaped isolation")
    if (data["render_fps"], data["sample_fps"], data["physics_tps"]) != (30, 10, 60):
        raise ValueError("unexpected capture rates")
    if data["end_process_frame"] - data["start_process_frame"] != seconds * 30:
        raise ValueError("wrong measured process frame delta")
    if abs(data["end_physics_frame"] - data["start_physics_frame"] - seconds * 60) > 2:
        raise ValueError("wrong measured physics delta")
    if len(data["samples"]) != seconds * 10 or len(frames) != seconds * 10:
        raise ValueError("wrong sampled-frame count")
    for i, (sample, frame) in enumerate(zip(data["samples"], frames)):
        if sample["frame"] != i * 3 or sample["png_sha256"] != digest(frame):
            raise ValueError("sample identity mismatch")
        delta = sample["process_frame"] - data["start_process_frame"]
        if delta != i * 3 + 1 or abs(sample["simulation_seconds"] - delta / 30) > 0.00001:
            raise ValueError("sample simulation time mismatch")
        if i and (sample["elapsed_usec"] <= data["samples"][i-1]["elapsed_usec"] or sample["physics_ticks"] <= data["samples"][i-1]["physics_ticks"]):
            raise ValueError("sample clocks are not monotonic")
        raw = frame.read_bytes()
        if raw[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", raw[16:24]) != expected_size:
            raise ValueError("bad PNG dimensions")
    if seconds >= 5:
        if abs(data["samples"][0]["position"][2] - data["samples"][-1]["position"][2]) < 1:
            raise ValueError("named movement did not move player")


def check_budget(scratch, destination, started, max_frames):
    files = [p for p in scratch.rglob("*") if p.is_file()]
    if time.monotonic() - started > 120 or sum(p.stat().st_size for p in files) > 64 * 1024**2:
        raise ValueError("independent wall-time/byte watchdog")
    if len(list((scratch / "frames").glob("frame_*.png"))) > max_frames:
        raise ValueError("independent frame watchdog")
    for path in (scratch, destination.parent):
        if shutil.disk_usage(path).free < 6 * 1024**3:
            raise ValueError("independent free-disk watchdog")


def stop_group(process):
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            break
        if sig == signal.SIGTERM:
            time.sleep(0.2)
    process.wait(timeout=5)


def interrupted(signum, _frame):
    raise RuntimeError("capture interrupted by signal " + str(signum))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    # This tool is deliberately a five-second probe, not a long-run recorder.
    parser.add_argument("--seconds", type=int, choices=range(1, 6), default=5)
    parser.add_argument("--tablet", action="store_true")
    args = parser.parse_args()
    if args.out.exists():
        raise ValueError("refusing to overwrite evidence")
    if shutil.disk_usage(ROOT).free < 6 * 1024**3:
        raise ValueError("less than 6 GiB free")
    identity = source_identity()
    version = subprocess.check_output(["/opt/homebrew/bin/godot", "--version"], timeout=10).decode().strip()
    if not version.startswith("4.7."):
        raise ValueError("Godot 4.7 required")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, interrupted)
    with tempfile.TemporaryDirectory(prefix="cobie-opening-probe-") as temporary:
        scratch = Path(temporary)
        home = scratch / "home"
        frames_dir = scratch / "frames"
        home.mkdir()
        frames_dir.mkdir()
        env = dict(os.environ)
        env.pop("PYTHONPATH", None)
        env.pop("VIRTUAL_ENV", None)
        for key in ("HOME", "CFFIXED_USER_HOME", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            env[key] = str(home)
        env["COBIE_TEST_SAVE_ROOT"] = str(home / "saves")
        cmd = ["/opt/homebrew/bin/godot", "--path", str(ROOT), "--resolution", "1280x720",
               "--fixed-fps", "30", "--script", "res://tools/evidence/salmon_opening_probe.gd",
               "--", "--output=" + str(frames_dir), "--seconds=" + str(args.seconds)]
        if args.tablet:
            cmd.append("--tablet")
        log = scratch / "engine.log"
        started = time.monotonic()
        process = None
        try:
            with log.open("w") as stream:
                process = subprocess.Popen(cmd, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
                last_count, last_progress = 0, started
                while process.poll() is None:
                    check_budget(scratch, args.out, started, args.seconds * 10)
                    count = len(list(frames_dir.glob("frame_*.png")))
                    if count != last_count:
                        last_count, last_progress = count, time.monotonic()
                    if time.monotonic() - last_progress > 30:
                        raise ValueError("independent frame-stall watchdog")
                    time.sleep(0.1)
            check_budget(scratch, args.out, started, args.seconds * 10)
            if process.returncode != 0:
                raise ValueError("Godot exit " + str(process.returncode))
            check_log(log.read_text())
            data = json.loads((frames_dir / "runtime.json").read_text())
            frames = sorted(frames_dir.glob("frame_*.png"))
            validate_receipt(data, frames, args.seconds, (1024, 768) if args.tablet else (1280, 720), home)
            if source_identity() != identity:
                raise ValueError("source changed during capture")
            shutil.copytree(frames_dir, args.out)
            shutil.copy2(log, args.out / "engine.log")
            (args.out / "source.json").write_text(json.dumps(identity, indent=2) + "\n")
            receipt = {"status": "PASS", "kind": "sampled_automated_native_motion", "seconds": args.seconds,
                       "source_sha256": identity["content_sha256"], "samples": len(frames),
                       "png_bytes": sum(p.stat().st_size for p in frames), "wall_seconds": time.monotonic() - started,
                       "command": cmd, "engine_version": version, "user_data_and_save_roots_isolated": True,
                       "human_acceptance": False, "canonical_WCB008L_evidence": False}
            (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
            print(json.dumps(receipt, indent=2))
        except Exception:
            args.out.mkdir(parents=True, exist_ok=True)
            if log.exists():
                shutil.copy2(log, args.out / "FAILED-engine.log")
            raise
        finally:
            if process is not None:
                stop_group(process)


if __name__ == "__main__":
    main()
