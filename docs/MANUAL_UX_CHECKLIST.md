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
- [ ] Starting either mission by mouse enters with aiming captured; keyboard launch shows `CLICK TO AIM` when required, and waiting for that click cannot kill the player.
- [ ] Pawstol, Barkshot, and Fetch Launcher have distinct fire/alternate fire, ammo, recoil, impact, and enemy reaction.
- [ ] On touch, the dedicated `ALT` button activates secondary fire without stealing either joystick finger; releasing, focus loss, pause, death, or app switching clears it.
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
- [ ] Compliance Hound and Walker directional atlases read consistently in idle, alert, locomotion, attack, hurt/stagger, phase, and death states without obvious row/angle popping.
- [ ] Entering the Compliance Lab always spawns the named Fetch Guard beside the Fetch Launcher route.
- [ ] Walker phases are readable with flight-stick-friendly aim windows.
- [ ] Enemy labels show calibrated live HP (30/40/80/220/1000), and the Walker actively closes to approximately seven metres.
- [ ] Walker health reaches `0% / DESTROYED`, live summons clear, and the bounded defeat spectacle completes before the Golden Tennis Ball appears; the ball never acts as boss damage.
- [ ] All six zones, gates, switches, keys, hazards, and final exit work from a clean run.
- [ ] The full route spawns all 17 required actors: 12 initial-wave actors plus five delayed shed/tunnel/lab reinforcements, including the arena boss; peak authored active density remains three.
- [ ] Sign read three times, cracked wall, and ball-return secrets each count once and reward the player.
- [ ] Victory totals and rank reflect the run; enemies/secrets cannot exceed declared totals.

## Rain City Run RC / public beta

Automated/package note (2026-07-16): the exact RC package rendered the title and mission selector at 1024×768, accepted the first activation tap without a focus-recovery detour, and emitted no game-origin Chrome error. The unchecked items below still require human route/device judgment.

- [ ] The normal mission selector shows `BETA`, `START BETA`, and a visible work-in-progress warning before launch.
- [ ] Rain City, Mount Hood, Moon, and Ventura are immediately available as public `BETA` missions on a fresh campaign; mission-aware victory actions advance through the five-mission episode without making direct public testing depend on save state.
- [ ] Clicking/tapping a card commits the selection without launching; hover/focus alone never changes the details or footer action, and only `START MISSION`/`START BETA` launches.
- [ ] The explicit Start action transfers focus/capture into gameplay; one non-firing click restores released pointer capture without opening a menu detour.
- [ ] `PLAY AGAIN` reloads the completed mission rather than always returning to Salmon Creek.
- [ ] The opening grants enough time to establish mouse/touch control without a spawn death and announces `PUBLIC BETA PREVIEW`.
- [ ] Downtown alley, Rain City Slice block, waterfront lanes, terminal service, and harbour pier form one continuous readable route.
- [ ] Four objectives and their checkpoints cannot be consumed early or restored into a dead end.
- [ ] All twenty authored interactions are grounded, discoverable, reset-safe, and tactically useful; all four secrets count once.
- [ ] Umbrella Shield Enforcer communicates brace, attack opening, shield break, hurt/stagger, and death; flanking, Barkshot, explosives, and Fetch ricochet remain viable counters.
- [ ] All four Towmaster phases—Appeal Filed, Appeal Denied, Final Notice, and Case Closed—change state and spawn the intended wave; module destruction, death, Continue, restart, and exit reset exactly once.
- [ ] The boss bar reads `MUNICIPAL TOWMASTER // APPEAL DENIED`, totals approximately 1,000 Classic HP, exposes modules in order, and leaves a persistent wreck.
- [ ] Compliance Gulls visibly mark, telegraph, dive, recover, and can be interrupted; no invisible buff or unavoidable attack occurs.
- [ ] Terminal Service awards Municipal Recall Override; Fetch recall is 35% faster and first recalled contact doubles shield/module stagger without increasing primary damage; checkpoint and campaign persistence behave correctly.
- [ ] Exactly 26 authored enemies appear over the mission while no more than 2/3/4 attack simultaneously on Story/Classic/Mayhem.
- [ ] `R` proactively reloads every partially depleted magazine, updates HUD state immediately, and plays the complete weapon-specific reload sequence.
- [ ] Harbour water/out-of-bounds falls kill and restore at the pier checkpoint rather than falling forever.
- [ ] Completing the convoy unlocks the departure control and campaign result; no earlier interaction can consume the departure switch.
- [ ] Route target: ______ minutes (15–22); human pacing, landmark, humor, art, and mix findings recorded separately.

## Mount Hood Whiteout public beta

- [ ] Selector shows `BETA`, `START BETA`, and the public-development warning; card selection never launches without Start.
- [ ] `PREPARING…` is truthful and Start enables only after mission warmup completes.
- [ ] Forest Pullout, Mountain Road, Snowbound Lodge, Service Tunnels, and Summit form a continuous readable route with the mountain as an intentional exterior landmark.
- [ ] Full/Reduced/Off surface movement settings produce bounded, understandable powder/ice response with identical desktop/touch physics.
- [ ] Five checkpoints and four secrets restore without progression loss; Municipal Recall is available on direct and campaign entry.
- [ ] Exactly 24 regular enemies appear while only 2/3/4 attack simultaneously on Story/Classic/Mayhem.
- [ ] Ski-Patrol Ranger telegraphs ranged attacks; Avalanche Recon Drone visibly marks, can be interrupted, and cleans up safely.
- [ ] Chairlift can board, move, complete, die/reset, and restore from checkpoint without stale motion or stranded actors.
- [ ] Snowcat phases read ROAD CLOSED, WHITEOUT WARNING, CHAINS REQUIRED, and OFF-LEASH SUMMIT; health reaches zero and summons clear before the Golden Ball becomes available.
- [ ] Snowbanks, firs, snowman, lodge, lift machinery, warm windows, signs, and mountain remain readable at 1024×768 without hiding enemies, pickups, objectives, captions, or touch controls.
- [ ] Target route: ______ minutes (18–25); human traction, boss fairness, art, mix, humor, motion, thermal, and photosensitivity findings recorded separately.

## Dark Side of Fetch public beta

- [ ] Landing pad, habitat, crater trench, satellite array, and Leashmaster crater have distinct authored reads and form one continuous route.
- [ ] The presentation kit uses manifested Moon materials without adding collision or navigation ownership; Earth remains a readable directional landmark.
- [ ] Low-gravity movement, vacuum hazards, checkpoints, five secrets, and every critical switch remain comprehensible on desktop and twin-stick touch.
- [ ] Lunar enemies and the 1,000-HP Leashmaster remain readable against regolith and habitat materials; its defeat reaches zero and gates the Golden Ball.
- [ ] Target route: ______ minutes; human movement comfort, combat readability, art, mix, humor, motion, thermal, and photosensitivity findings recorded separately.

## Pier Pressure public beta

- [ ] Service lane, Surfers Point, marina docks, Ventura Pier, and offshore platform read as a warm coastal mission rather than generic blockout.
- [ ] The presentation kit uses manifested Ventura materials without adding collision or navigation ownership; ocean, palms, pier, marina, and sunset landmarks remain readable.
- [ ] Tide/surf hazards, checkpoints, five secrets, route switches, and every critical pickup remain grounded and reset-safe.
- [ ] The 1,000-HP Tidebreaker reaches zero, leaves its authored defeat state, and gates the Golden Ball exactly once.
- [ ] Target route: ______ minutes; human combat pacing, art, mix, humor, motion, thermal, and photosensitivity findings recorded separately.

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
