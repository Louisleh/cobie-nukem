# Asset Manifest

Every committed visual, audio, font, model, texture, and shader asset must have an entry before release. Generated assets must record the generator/tool and a concise prompt or process note. Do not commit unlicensed placeholders.

| Path | Description | Source/creator | License or permission | Modifications | Verification |
| --- | --- | --- | --- | --- | --- |
| `assets/brand/cobie_nukem_cover.png` | Original Cobie title-screen cover illustration | Generated for this project with OpenAI image generation on 2026-07-10 | Project-original generated asset; owner should still review publication rights and working-title clearance | Prompt specified an apricot labradoodle in aviators/leather jacket, PNW sports field, original drones/Walker, Golden Tennis Ball, no logos/franchise designs/text/watermark | Source prompt recorded in build-session handoff; visually reviewed |
| `resources/ui/retro_theme.tres` | Safety-yellow, wet-asphalt retro interface theme | Original procedural Godot resource authored for this project | Project-original | Uses only Godot primitives and the engine default font | Source-inspectable |
| `scripts/ui/cobie_portrait.gd` | Procedurally drawn Cobie HUD portrait with fur, aviators, and leather jacket | Original code-authored vector primitives | Project-original | Damage states alter palette and add marks | Source-inspectable |
| `scripts/ui/procedural_audio.gd` | Synthesized menu music, interface, weapon, pickup, hit, hurt, secret, and victory cues | Original runtime synthesis authored for this project | Project-original | 22.05 kHz mono waveforms generated from oscillators and deterministic noise; no samples used | Source-inspectable |
