# Original production SFX source

`generate_production_sfx.py` deterministically renders the short production
sound-effects library using only Python's standard library, fixed random seeds,
oscillators, filtered noise, and amplitude envelopes. It consumes no recordings,
voice models, third-party samples, or protected game material.

The design vocabulary is original to Cobie Nukem: low, weighty weapon reports;
distinct metal/pneumatic action layers; synthetic municipal-machine enemy cues;
and soil, concrete, wood, and metal footsteps. No cue attempts to reproduce a specific
commercial game, actor, quotation, performance, or sound effect.

Run from the repository root:

```bash
python3 assets/audio/source/generate_production_sfx.py
```

Output is 44.1 kHz, 16-bit, mono PCM WAV for low-latency Godot and Web playback.
`assets/audio/SHA256SUMS.txt` makes regeneration byte-verifiable.
