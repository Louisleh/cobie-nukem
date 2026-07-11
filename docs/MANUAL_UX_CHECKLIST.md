# Manual UX and Playthrough Checklist

Record build/commit: __________  Godot: __________  OS/device: __________  Tester/date: __________

## Launch and navigation

- [ ] Native build launches to an intentional title/menu in under 10 seconds.
- [ ] Cover/title is readable; no inaccurate Windows/platform badge appears.
- [ ] New Game, Continue, Input Setup, Options, Credits, and native Quit behave correctly.
- [ ] Back/Escape always returns to a safe screen; no keyboard-only trap exists.
- [ ] Focus loss pauses or safely suppresses gameplay input and audio.
- [ ] Clean install and existing settings/save both behave correctly.

## Input setup and diagnostics

- [ ] Keyboard/mouse defaults match README and all actions can be remapped.
- [ ] Device list, identity/GUID, raw axes, raw buttons, action values, dead zones, and last-input time update.
- [ ] Rest/min/max calibration and per-axis inversion/sensitivity/curve behave visibly.
- [ ] Binding conflicts are explained and resolvable; reset restores a playable profile.
- [ ] Saved profile survives restart and unplug/replug does not require game restart.
- [ ] Browser labels joystick support experimental and recommends native Mac.
- [ ] Diagnostics report exports and contains no unexpected personal data.

## Gameplay and pacing

- [ ] Within 30 seconds: Cobie identity, firing, rule-breaking joke, and first enemy are clear.
- [ ] Movement is responsive at walk/run/jump and never sticks after pause/focus change.
- [ ] Pawstol, Barkshot, and Fetch Launcher have distinct fire/alternate fire, ammo, recoil, impact, and enemy reaction.
- [ ] Off/Light/Classic/Heavy auto-aim are distinguishable; no target behind player or through walls is selected.
- [ ] Treats, armor, ammunition, power-ups, access collar, and water bowl provide clear feedback.
- [ ] Death/restart and checkpoint restore a completable state.
- [ ] First-playthrough duration: ______ minutes (target 12–20).

## Encounters and level completion

- [ ] Drone bolt, Groundskeeper charge, and Squirrel acorn have readable audiovisual telegraphs.
- [ ] Compliance Hound dash/shield/weak point are understandable and armor drop appears.
- [ ] Walker phases are readable with flight-stick-friendly aim windows.
- [ ] Golden Tennis Ball becomes available only in the final phase and finishes the boss once.
- [ ] All six zones, gates, switches, keys, hazards, and final exit work from a clean run.
- [ ] Sign read three times, cracked wall, and ball-return secrets each count once and reward the player.
- [ ] Victory totals and rank reflect the run; enemies/secrets cannot exceed declared totals.

## Accessibility and presentation

- [ ] HUD health/armor/ammo/weapon/key/crosshair remain legible at 16:9, 16:10, and ultrawide.
- [ ] Information is not communicated by color alone; interaction prompts have sufficient contrast.
- [ ] FOV, volume, auto-aim, run toggle/hold, gore, head bob, shake, and flash settings apply and persist.
- [ ] Reduced flashes/shake materially reduce the effect without hiding required state.
- [ ] All meaningful speech/audio has a text equivalent; Web audio starts only after interaction.
- [ ] Pixel scaling is crisp and aspect ratio is preserved without distorted 3D/UI.

## Platform and release

- [ ] Native full keyboard/mouse playthrough completed on target Apple-silicon Mac.
- [ ] Web full keyboard/mouse playthrough completed in Chrome over HTTPS.
- [ ] Web full keyboard/mouse playthrough completed in Safari over HTTPS.
- [ ] No-controller startup and controller disconnect/reconnect are safe.
- [ ] Exact joystick/adapter/macOS acceptance procedure recorded, or README remains explicitly unverified.
- [ ] Asset manifest, known issues, release notes, hashes, and unsigned/notarization status are accurate.

Final disposition: [ ] PASS  [ ] FAIL  Blockers/issue links: __________________________________________

