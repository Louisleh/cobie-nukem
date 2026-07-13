# Manual UX and Playthrough Checklist

Record build/commit: __________  Godot: __________  OS/device: __________  Tester/date: __________

## Launch and navigation

- [ ] Native build launches to an intentional title/menu in under 10 seconds.
- [ ] Web shows the normalized loading splash while initializing; the canvas is viewport-sized before its first visible title/menu frame.
- [ ] Cover/title is readable; no inaccurate Windows/platform badge appears.
- [ ] New Game, Continue, Input Setup, Options, Credits, and native Quit behave correctly.
- [ ] Back/Escape always returns to a safe screen; no keyboard-only trap exists.
- [ ] Focus loss pauses or safely suppresses gameplay input and audio.
- [ ] Clean install and existing settings/save both behave correctly.

## Input setup and diagnostics

- [ ] Keyboard/mouse defaults match README and all actions can be remapped.
- [ ] Default key and mouse bindings are visible without clipping at 1280×720; both diagnostics columns scroll independently.
- [ ] Device list, identity/GUID, raw axes, raw buttons, action values, dead zones, and last-input time update.
- [ ] Rest/min/max calibration and per-axis inversion/sensitivity/curve behave visibly.
- [ ] Binding conflicts are explained and resolvable; reset restores a playable profile.
- [ ] Saved profile survives restart and unplug/replug does not require game restart.
- [ ] Browser labels joystick support experimental and recommends native Mac.
- [ ] Diagnostics report exports and contains no unexpected personal data.

## Gameplay and pacing

- [ ] Within 30 seconds: Cobie identity, firing, rule-breaking joke, and first enemy are clear.
- [ ] Opening enemies stay dormant until the first player shot or the 12-second safety timeout; standing still during onboarding does not cause immediate damage.
- [ ] Movement is responsive at walk/run/jump and never sticks after pause/focus change.
- [ ] Enemies and pickups begin at their intended height without an initial sink/teleport; enemy motion remains smooth.
- [ ] Pickups remain anchored above the floor, grounded enemies cannot fall below y=0, and drones hover without gravity jitter.
- [ ] Breaking the cracked lab wall removes all collision and reveals a continuous floor bridge into the Secret Dog Park.
- [ ] Losing browser/native pointer capture is recoverable with one click; that click does not fire.
- [ ] Pawstol, Barkshot, and Fetch Launcher have distinct fire/alternate fire, ammo, recoil, impact, and enemy reaction.
- [ ] Up/Down changes exactly one weapon per press without flicker; 1/2/3 selects unlocked weapons directly; mouse wheel changes one step per debounced gesture.
- [ ] Pawstol produces readable light knockback, Barkshot produces controlled aggregate knockback, and Fetch balls rebound from enemies.
- [ ] Every weapon has a visible muzzle burst; enemy hits, surface impacts, and misses have distinct feedback.
- [ ] Off/Light/Classic/Heavy auto-aim are distinguishable; no target behind player or through walls is selected.
- [ ] Treats, armor, ammunition, power-ups, access collar, and water bowl provide clear feedback.
- [ ] Walking through every pickup type collects it reliably, including when the player begins already overlapping it.
- [ ] Health, armor, ammo, and weapon pickups collect promptly even when the corresponding resource is already full/unlocked.
- [ ] Collecting the access collar changes the HUD from `NO ACCESS COLLAR` to `ACCESS COLLAR` before opening the gate.
- [ ] Death/restart and checkpoint restore a completable state.
- [ ] Falling below the level kill plane triggers the normal death screen and checkpoint retry instead of falling forever.
- [ ] First-playthrough duration: ______ minutes (target 12–20).

## Encounters and level completion

- [ ] Drone bolt, Groundskeeper charge, and Squirrel acorn have readable audiovisual telegraphs.
- [ ] Compliance Hound dash/shield/weak point are understandable and armor drop appears.
- [ ] Entering the Compliance Lab always spawns the named Fetch Guard beside the Fetch Launcher route.
- [ ] Walker phases are readable with flight-stick-friendly aim windows.
- [ ] Enemy labels show calibrated live HP (30/40/80/220/1000), and the Walker actively closes to approximately seven metres.
- [ ] Golden Tennis Ball becomes available only in the final phase and finishes the boss once.
- [ ] All six zones, gates, switches, keys, hazards, and final exit work from a clean run.
- [ ] The full route spawns all 17 required actors: 12 initial-wave actors plus five delayed shed/tunnel/lab reinforcements, including the arena boss; peak authored active density remains three.
- [ ] Sign read three times, cracked wall, and ball-return secrets each count once and reward the player.
- [ ] Victory totals and rank reflect the run; enemies/secrets cannot exceed declared totals.

## Accessibility and presentation

- [ ] HUD health/armor/ammo/weapon/key/crosshair remain legible at 16:9, 16:10, and ultrawide.
- [ ] Information is not communicated by color alone; interaction prompts have sufficient contrast.
- [ ] FOV, volume, mouse/trackpad look speed, auto-aim, run toggle/hold, gore, head bob, shake, and flash settings apply and persist.
- [ ] Reduced flashes/shake materially reduce the effect without hiding required state.
- [ ] Opening Options during play returns to the same paused run with Resume available.
- [ ] Mouse wheel and keyboard focus can reach every Options row; focus scrolling never covers the title or Reset/Back buttons.
- [ ] Escape closes pause, pause and death never stack, and losing application focus opens a safe pause state.
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
