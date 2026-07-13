#!/usr/bin/env python3
"""Deterministically render Cobie Nukem's original production SFX tranche.

This generator uses only Python's standard library, elementary synthesis, and
fixed seeds. It does not ingest, clone, or imitate any recording, performance,
or third-party game asset. Run from the repository root:

    python3 assets/audio/source/generate_production_sfx.py
"""

from __future__ import annotations

import hashlib
import math
import random
import struct
import wave
from pathlib import Path
from typing import Callable


RATE = 44_100
ROOT = Path(__file__).resolve().parents[1]


def _render(relative_path: str, duration: float, synthesizer: Callable[[float, random.Random], float], seed: int) -> None:
    path = ROOT / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    rng = random.Random(seed)
    samples = [synthesizer(index / RATE, rng) for index in range(max(1, round(duration * RATE)))]
    peak = max(max(abs(value) for value in samples), 0.001)
    gain = min(0.92 / peak, 1.0)
    pcm = b"".join(struct.pack("<h", round(max(-1.0, min(1.0, sample * gain)) * 32767)) for sample in samples)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm)


def _decay(t: float, duration: float, power: float = 2.0) -> float:
    return max(0.0, 1.0 - t / duration) ** power


def _noise_filter(cutoff: float) -> Callable[[random.Random], float]:
    state = 0.0

    def sample(rng: random.Random) -> float:
        nonlocal state
        state += cutoff * (rng.uniform(-1.0, 1.0) - state)
        return state

    return sample


def weapon_shot(kind: str, variant: int) -> tuple[float, Callable[[float, random.Random], float]]:
    settings = {
        "pawstol": (0.22, 92.0, 0.52, 0.24),
        "barkshot": (0.48, 52.0, 0.78, 0.44),
        "fetch_launcher": (0.34, 76.0, 0.42, 0.34),
    }
    duration, body_hz, noise_amount, tail = settings[kind]
    filtered = _noise_filter(0.18 if kind == "barkshot" else 0.28)

    def synth(t: float, rng: random.Random) -> float:
        progress = t / duration
        crack = rng.uniform(-1.0, 1.0) * math.exp(-t * (95.0 if kind != "barkshot" else 62.0))
        body = math.sin(math.tau * body_hz * (1.0 - 0.28 * progress) * t)
        body += 0.42 * math.sin(math.tau * body_hz * 0.51 * t + variant * 0.37)
        noise = filtered(rng)
        if kind == "fetch_launcher":
            pneumatic = math.sin(math.tau * (210.0 - 125.0 * progress) * t) * math.exp(-t * 10.0)
            return 0.52 * pneumatic + 0.34 * noise * _decay(t, duration, 1.4) + 0.18 * crack
        return (0.42 * body + noise_amount * noise + 0.44 * crack) * _decay(t, duration, tail * 4.0)

    return duration, synth


def metal_action(kind: str, variant: int, phase: str) -> tuple[float, Callable[[float, random.Random], float]]:
    phase_settings = {
        "mechanical": (0.105, 690.0, 0.68),
        "empty": (0.095, 430.0, 0.54),
        "switch": (0.16, 250.0, 0.48),
        "reload_start": (0.18, 310.0, 0.56),
        "reload_step": (0.145, 520.0, 0.62),
        "reload_complete": (0.19, 390.0, 0.68),
    }
    duration, frequency, brightness = phase_settings[phase]
    pitch_scale = {"pawstol": 1.12, "barkshot": 0.72, "fetch_launcher": 0.86}[kind]
    frequency *= pitch_scale * (1.0 + variant * 0.018)

    def synth(t: float, rng: random.Random) -> float:
        ring = math.sin(math.tau * frequency * t) + 0.48 * math.sin(math.tau * frequency * 1.73 * t)
        click = rng.uniform(-1.0, 1.0) * math.exp(-t * 85.0)
        second_t = max(0.0, t - duration * 0.52)
        second = math.sin(math.tau * frequency * 0.71 * second_t) * math.exp(-second_t * 38.0) if second_t > 0 else 0.0
        return (ring * brightness * 0.42 + click * 0.36 + second * 0.34) * _decay(t, duration, 1.6)

    return duration, synth


def enemy_cue(phase: str, variant: int) -> tuple[float, Callable[[float, random.Random], float]]:
    settings = {"alert": (0.42, 118.0), "attack": (0.34, 104.0), "hurt": (0.28, 82.0), "death": (0.72, 68.0)}
    duration, base = settings[phase]
    filtered = _noise_filter(0.11)

    def synth(t: float, rng: random.Random) -> float:
        progress = t / duration
        if phase == "alert":
            pitch = base + 90.0 * progress + 18.0 * math.sin(math.tau * 4.0 * t)
            phase_offset = variant * 0.41
            alarm = math.sin(math.tau * pitch * t + phase_offset) + 0.35 * math.sin(math.tau * pitch * 2.02 * t + phase_offset * 0.7)
            gate = 0.42 + 0.58 * (1.0 if int(t * 14.0 + variant) % 2 == 0 else 0.25)
            return alarm * gate * _decay(t, duration, 0.55) * 0.48
        if phase == "attack":
            windup = math.sin(math.tau * (base + 86.0 * progress) * t + variant * 0.33)
            bite = math.sin(math.tau * base * 0.48 * t + 2.7 * math.sin(math.tau * 24.0 * t))
            transient = rng.uniform(-1.0, 1.0) * math.exp(-t * 36.0)
            return (windup * 0.46 + bite * 0.34 + transient * 0.28) * _decay(t, duration, 1.0)
        pitch = base * (1.0 - (0.48 if phase == "death" else 0.22) * progress)
        growl = math.sin(math.tau * pitch * t + 3.4 * math.sin(math.tau * 31.0 * t))
        grit = filtered(rng)
        impact = rng.uniform(-1.0, 1.0) * math.exp(-t * 48.0)
        return (growl * 0.46 + grit * 0.42 + impact * 0.32) * _decay(t, duration, 1.4)

    return duration, synth


def footstep(surface: str, variant: int) -> tuple[float, Callable[[float, random.Random], float]]:
    settings = {
        "soil": (0.18, 58.0, 0.11, 0.50),
        "concrete": (0.15, 82.0, 0.25, 0.32),
        "wood": (0.19, 72.0, 0.20, 0.38),
        "metal": (0.22, 96.0, 0.42, 0.18),
    }
    duration, body_hz, ring_amount, noise_amount = settings[surface]
    filtered = _noise_filter(0.13 if surface == "soil" else 0.3)

    def synth(t: float, rng: random.Random) -> float:
        thump = math.sin(math.tau * (body_hz + variant * 2.5) * t) * math.exp(-t * 34.0)
        grit = filtered(rng) * _decay(t, duration, 1.8)
        ring = math.sin(math.tau * (520.0 + variant * 31.0) * t) * math.exp(-t * 22.0)
        return thump * 0.48 + grit * noise_amount + ring * ring_amount

    return duration, synth


def main() -> None:
    generated: list[Path] = []
    for weapon_index, kind in enumerate(("pawstol", "barkshot", "fetch_launcher")):
        for phase, count in (("shot", 2), ("mechanical", 2), ("empty", 2), ("switch", 2), ("reload_start", 1), ("reload_step", 2), ("reload_complete", 1)):
            for variant in range(1, count + 1):
                duration, synth = weapon_shot(kind, variant) if phase == "shot" else metal_action(kind, variant, phase)
                relative = f"weapons/{kind}/{phase}_{variant:02d}.wav"
                _render(relative, duration, synth, 0xC0B1E + weapon_index * 1000 + len(phase) * 31 + variant)
                generated.append(ROOT / relative)
    for phase_index, phase in enumerate(("alert", "attack", "hurt", "death")):
        for variant in range(1, 4):
            duration, synth = enemy_cue(phase, variant)
            relative = f"enemies/shared/{phase}_{variant:02d}.wav"
            _render(relative, duration, synth, 0xE11E0 + phase_index * 100 + variant)
            generated.append(ROOT / relative)
    for surface_index, surface in enumerate(("soil", "concrete", "wood", "metal")):
        for variant in range(1, 4):
            duration, synth = footstep(surface, variant)
            relative = f"footsteps/{surface}_{variant:02d}.wav"
            _render(relative, duration, synth, 0xF0075 + surface_index * 100 + variant)
            generated.append(ROOT / relative)
    checksums = [f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.relative_to(ROOT)}" for path in sorted(generated)]
    (ROOT / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n", encoding="utf-8")
    print(f"Rendered {len(generated)} original mono WAV files at {RATE} Hz")


if __name__ == "__main__":
    main()
