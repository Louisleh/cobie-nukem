# Cobie Nukem: Retro Mayhem 3D
## Research-Informed Product Requirements Document + Codex Autonomous Build Goal

**Document status:** Original vertical-slice requirements; implementation status is maintained in `docs/PHASE_ROADMAP_PRD.md`
**Working title:** *Cobie Nukem: Retro Mayhem 3D*  
**Primary platform:** macOS, especially Apple-silicon Mac mini  
**Secondary platform:** Browser-playable Web export  
**Engine:** Godot 4.7 stable, standard/GDScript build  
**Product scope:** Salmon Creek is the definitive opening mission; Rain City Run is the second production mission and remains explicitly labeled public beta/RC until human gates pass, while later campaign missions remain locked teasers
**Core fantasy:** Play as Cobie, an aviator-sunglasses-and-leather-jacket labradoodle action hero, in an original 1990s-style retro FPS designed to feel unusually good on a low-cost flight stick.

---

# 1. Executive Summary

Build a compact, original retro first-person shooter inspired by the design grammar of 1990s “boomer shooters”: fast movement, readable enemies, sprite-based opponents, environmental jokes, secret rooms, chunky weapons, absurd confidence, and immediate action.

The game must not reproduce or distribute Duke Nukem code, maps, characters, dialogue, logos, music, sound effects, or other protected assets. “Cobie Nukem” is a working title for a personal prototype. Before a public commercial release, perform a naming and IP review and strongly consider a more distinct release title such as **Cobie: Fetch This!**, **Cobie Unleashed**, or **Retro Fetch 3D**.

The vertical slice opens at a stormy Pacific Northwest sports field beside a sign reading **“NO ANIMALS ON SPORTS FIELD.”** Cobie, wearing sunglasses and a black leather jacket, immediately ignores it. An alien-mechanical occupation has converted the grounds, nearby maintenance tunnels, and an underground “Animal Compliance” facility into a hostile zone. Cobie must recover the stolen **Golden Tennis Ball**, expose the facility, defeat the Animal Control Walker, and leave through a spectacularly unnecessary explosion.

The primary control novelty is a **flight-stick mode** with exaggerated auto-aim and a 1990s-style control philosophy. Keyboard/mouse remains fully supported. A standard gamepad is a fallback.

## 1.1 Alpha.9 public-beta checkpoint

Alpha.9 preserves the Rain City Forge systems and exposes Vancouver through an unmistakable `BETA` mission card and work-in-progress warning so source and public development remain closely aligned. Browser pointer capture is scene-owned, requested from the trusted mission-launch gesture, recoverable with one non-firing click, and backed by a visible HUD prompt plus activation safety protection. Vancouver adds a ten-second opening protection window but remains a rough production preview without a claimed human end-to-end playthrough. The detailed completed/remaining ledger, evidence, and human gates live only in `docs/PHASE_ROADMAP_PRD.md`.

## 1.2 Rain City Run RC stabilization checkpoint

The public `0.7.0-alpha.1-rc2` stabilization RC hardens the campaign-unlocked second mission after the initial public RC. It preserves five authored gameplay/presentation zones, 26 enemies with difficulty-specific pressure caps, the Compliance Gull, Umbrella Shield Enforcer, four secrets, save schema v5, Municipal Recall Override, and the four-phase 1,000-HP Municipal Towmaster finale while adding deterministic route gates, collectible secret rewards, shield/attack/pressure fixes, bounded navigation recovery, truthful Rain City performance coverage, transactional completion saves, and serialized crash-safe Godot automation. The `BETA` badge and opening warning remain until physical iPad, target-Mac, browser, pacing, art, mix, fairness, humor, and photosensitivity gates receive human approval. Automated completion evidence and release identity are maintained in `docs/PHASE_ROADMAP_PRD.md`.

---

# 2. Research Conclusions and Technical Decisions

## 2.1 Engine decision: Godot 4.7 + GDScript

Use **Godot 4.7 stable**, pinned in repository documentation and CI.

Reasons:

- Native macOS editor and export support.
- Official macOS builds support Apple Silicon and Intel.
- Official export templates produce Universal 2 macOS applications.
- Godot supports keyboard, mouse, controllers, and joysticks on macOS.
- Godot 4.5+ uses SDL 3 for desktop controller input.
- GDScript supports browser export; Godot 4 C# projects currently do not.
- Text-heavy scene, resource, and script formats are suitable for Codex.
- The Compatibility renderer is sufficient for low-resolution retro 3D.

Use the standard Godot build, not .NET/C#.

## 2.2 Renderer and visual technique

Use **true 3D geometry presented as 2.5D retro art**:

- Authored low-poly 3D level geometry, collision, navigation, landmarks, and modular production kits.
- Original high-resolution illustrated or Blender-rendered directional billboard enemies.
- Original illustrated or low-poly weapon viewmodels with stable proportions and explicit animation states.
- A 640×360 clean-retro internal baseline with linear canvas filtering; lower quality tiers reduce effects and density rather than shrinking characters into unreadable pixels.
- Fog, authored baked/static lighting, restrained dynamic key lights, decals, and bounded VFX selected by quality profile.
- Web-safe texture atlases sized from the canonical view and performance budget rather than an arbitrary 64px limit.
- Deliberately economical animation timing without duplicated placeholder frames or inconsistent directional scale.
- A fixed sprite-authoring contract: atlas cell size, opaque-frame height, feet baseline, direction order, intended world height, and `pixel_size = intended_world_height / opaque_frame_height` are manifested and mechanically validated.
- A distinct environmental identity for every mission, defined in `docs/ART_BIBLE.md` before production art is accepted.
- No requirement for a custom raycasting or Build-engine clone.

This captures the speed and readability of classic 2.5D shooters while retaining modern clarity. A pure pixel-art rewrite is explicitly out of scope: it would reduce asset complexity, but would discard the current authored-world direction and would not solve inconsistent scale, animation, collision, or encounter design. Those are addressed through the shared production contract instead.

## 2.3 Distribution decision

Produce two builds:

1. **Canonical native macOS build**
   - Best input compatibility.
   - Primary experience for the flight stick.
   - Export as `.app` and `.zip`; optionally `.dmg`.
   - Signing and notarization are a later release task requiring Apple credentials.

2. **Browser demo**
   - Keyboard/mouse is the guaranteed primary input.
   - Flight-stick support is explicitly labeled experimental.
   - Export without threads initially for simpler GitHub Pages and itch.io deployment.
   - Use secure HTTPS hosting.
   - Show an input-detection screen before gameplay.

The browser’s Gamepad API can mis-map specialized controllers and does not reliably expose enough device identity information for automatic model-specific remapping. The native build is therefore the authority for joystick support.

---

# 3. Hardware Recommendation and Compatibility Specification

## 3.1 Recommended budget flight stick

### Primary recommendation
**Thrustmaster USB Joystick, model 2960623**

**Current target price:** approximately **$24.99**  
**Expected all-in cost for the M4 Mac mini:** approximately **$32–40**, including a basic USB-A-to-USB-C adapter or hub.

Manufacturer-listed hardware characteristics:

- Three axes.
- Four buttons plus one trigger.
- Thumb throttle.
- Weighted base.
- Plug-and-play USB operation.
- Approximately 626 g.

### Critical compatibility truth

This is the best fit for the intended experience and budget, but it is **not currently guaranteed by Thrustmaster for general macOS gaming**. The current manufacturer product page lists PC as the supported platform. Legacy and retailer listings sometimes describe the same model as PC/Mac, and standard USB HID devices are often visible to macOS without custom drivers, but this is not equivalent to a current official guarantee.

Therefore:

- Treat the device as **provisionally supported pending a physical smoke test**.
- Build the game around raw configurable joystick input rather than model-specific drivers.
- Include a first-class input diagnostics and calibration scene.
- Do not block development on possession of the hardware.
- Do not claim “verified on macOS” until the actual unit passes the acceptance test below.

### M4 Mac mini connection requirement

The current M4 Mac mini exposes USB-C/Thunderbolt ports and no USB-A ports. The joystick uses USB-A, so the setup requires:

- USB-A female to USB-C male adapter, or
- powered/unpowered USB-C hub with USB-A ports.

No special bandwidth is needed.

## 3.2 Compatibility-safe alternative

### Hyperkin Trooper 2
Approximate price: **$30–31**  
Explicitly sold for PC, Mac, Linux, and Raspberry Pi.

Tradeoff:

- More Atari/arcade-style than flight-stick style.
- Four-way digital joystick rather than a useful multi-axis analog flight stick.
- Excellent novelty and compatibility fallback.
- Inferior for smooth turning and movement.

## 3.3 Practical fallback

A $20–40 Mac-compatible standard gamepad can serve as a QA fallback, but it is not the defining hardware concept. The game must always remain fully playable with keyboard/mouse.

## 3.4 Native joystick acceptance test

The Thrustmaster 2960623 is considered “Cobie Nukem verified” only when all tests pass on the target Mac mini:

1. macOS enumerates the device after connection through the chosen adapter/hub.
2. Godot reports a connected device with a stable device index and name or GUID.
3. Stick X and Y produce full-range values without locking.
4. Thumb throttle produces a distinct analog axis.
5. Trigger and all four buttons register independently.
6. POV control registers as buttons or hat values.
7. Input remains stable for 20 minutes.
8. Device reconnects after unplug/replug without restarting the game.
9. Dead-zone calibration suppresses resting drift.
10. Native game maintains frame-time targets while polling input.
11. Saved bindings survive restart.
12. No action remains permanently unavailable due to insufficient buttons.

If a control is missing or misreported, the remapping UI must allow a functional reduced mapping.

## 3.5 Browser joystick acceptance test

Browser flight-stick support is optional/experimental. A browser build passes when:

- The game runs over HTTPS.
- The input screen instructs the player to press a button to activate gamepad detection.
- Connected axes and buttons are visualized.
- Manual remapping is possible.
- A bad browser mapping cannot trap the user; keyboard/mouse recovery always works.
- The UI clearly recommends the native Mac build for flight sticks.

---

# 4. Product Vision

## 4.1 One-sentence pitch

**A fast, funny, 1990s-style FPS starring a leather-jacketed labradoodle, built around ridiculous auto-aim, environmental jokes, secret rooms, and a $25 flight stick.**

## 4.2 Player promise

Within 30 seconds, the player should:

- Understand that Cobie is the hero.
- Fire a satisfying weapon.
- Break a rule.
- Hear or read a joke.
- Find the first enemy.
- Feel that the flight stick is not a gimmick but a deliberate control style.

## 4.3 Design pillars

### 1. Immediate tactile fun
Movement, firing, hit reactions, pickups, and doors must feel responsive before visual polish.

### 2. Cobie-specific personality
The game should be impossible to mistake for a generic retro FPS with a dog skin.

### 3. Flight-stick legitimacy
The control scheme should feel historically plausible and intentionally assisted, not merely tolerated.

### 4. Dense environmental humor
Jokes should live in signs, props, enemy behavior, pickup descriptions, and level layout rather than long cutscenes.

### 5. Small but complete
A finished 15-minute level is better than an unfinished campaign.

---

# 5. Target Audience

Primary:

- The project owner and friends.
- Players nostalgic for 1990s PC shooters.
- Mac owners who enjoy compact browser or indie games.
- People amused by Cobie as an action hero.

Secondary:

- Players with unusual controllers.
- Godot and Codex-development audiences.
- Casual players who need forgiving auto-aim.

Not a target:

- Competitive FPS players.
- Photorealistic-shooter audiences.
- Players expecting a multi-hour campaign in v1.

---

# 6. Scope

## 6.1 Vertical slice target

**12–20 minutes on a first playthrough.**

Includes:

- Title screen.
- Intro sting.
- One complete level.
- Three regular enemy types.
- One miniboss or elite.
- One final boss.
- Three weapons.
- Health, armor, ammo, and temporary power-up.
- Doors, switches, keycards, secrets, breakables, hazards.
- Five to eight environmental jokes.
- Three or more secrets.
- One checkpoint.
- Death/restart.
- Victory screen and score summary.
- Keyboard/mouse, flight stick, and generic gamepad bindings.
- Native macOS export.
- Browser export.
- Input calibration and remapping.
- Automated smoke tests and documented manual tests.

## 6.2 Explicitly out of scope

- Multiplayer.
- Procedural campaign generation.
- Full voice-acted cinematic story.
- More than one polished level.
- Online accounts.
- Cloud saves.
- Mod SDK.
- Mobile release.
- Console release.
- Photorealistic art.
- Direct use of Duke Nukem assets or dialogue.
- Apple notarization without credentials.
- Guaranteed support for every HOTAS device.

---

# 7. Narrative and World

## 7.1 Premise

During an unusually dramatic Pacific Northwest storm, Cobie approaches the Salmon Creek sports field and encounters a sign:

> NO ANIMALS ON SPORTS FIELD

Cobie points at the sign, then steps through the gate.

At that moment, the **Municipal Animal Compliance Network** activates. What appears to be a petty local rule is actually the front end of an alien-machine occupation using park infrastructure to harvest play, joy, and tennis-ball kinetic energy.

The system steals Cobie’s Golden Tennis Ball and seals the field.

Cobie responds with appropriate restraint: none.

## 7.2 Tone

- Affectionate parody of 1990s action excess.
- Confident, ridiculous, never cruel.
- Cobie is chaotic but lovable.
- Enemies are robots, mutants, or absurd monsters.
- Violence is stylized and optionally reducible.
- Humor is visual and situational.
- Minimal exposition.

## 7.3 Level title

**Episode 1, Level 1: NO DOGS ALLOWED**

Possible alternate level subtitle:

**The Salmon Creek Incident**

## 7.4 Story beats

1. **Cold open:** Cobie at the forbidden sports field.
2. **Inciting action:** compliance drones steal the Golden Tennis Ball.
3. **Field assault:** learn movement, fire, pickups, and auto-aim.
4. **Maintenance access:** discover the municipal facility.
5. **Compliance laboratory:** learn why play energy is being harvested.
6. **Secret dog park:** optional high-value reward room.
7. **Boss arena:** Animal Control Walker.
8. **Victory:** Cobie retrieves the ball and triggers an oversized explosion.
9. **End card:** “THEY SAID NO ANIMALS. THEY SHOULD HAVE SAID PLEASE.”

---

# 8. Core Gameplay Loop

1. Enter a readable combat space.
2. Identify high-priority targets.
3. Move aggressively and use assisted aiming.
4. Collect ammo, treats, and armor.
5. Inspect the environment for jokes and secrets.
6. Find a switch, access card, or route.
7. Unlock the next area.
8. Escalate weapon and enemy complexity.
9. Reach a set-piece or boss.
10. Receive score, secrets, completion time, and “good dog” rank.

---

# 9. Player Mechanics

## 9.1 Movement

Required:

- Forward/back.
- Strafe left/right.
- Turn/yaw.
- Optional vertical look.
- Run.
- Jump.
- Crouch optional; omit if it does not improve level design.
- Use/interact.
- Weapon selection.
- Fire and alternate fire.
- Pause.

Movement feel:

- Fast but controllable.
- Ground acceleration rather than instant full velocity.
- Air control light-to-moderate.
- No stamina.
- No realistic inertia.
- Step height forgiving.
- Automatic pickup collection.
- Optional head bob slider.
- Optional camera shake slider.

Suggested defaults:

- Walk speed: 6 m/s.
- Run speed: 9 m/s.
- Jump velocity: tuned for readable waist-high obstacles.
- Native target: 60 FPS.
- Web target: stable 30+ FPS, preferably 60.

## 9.2 Auto-aim

Auto-aim is a core feature, not an accessibility afterthought.

Modes:

- Off.
- Light.
- Classic.
- Heavy.

Classic default for flight-stick mode:

- Stronger vertical than horizontal assistance.
- Prioritize visible enemies closest to reticle direction.
- Require line of sight.
- Prefer enemies in weapon range.
- Soft magnetic pull, not hard camera snapping.
- Hitscan can bend slightly toward target.
- Projectiles receive limited launch correction.
- Never select targets behind the player.
- Clearly disable or reduce assistance for secrets and precision switches.

Expose tuning as resources:

- Horizontal cone.
- Vertical cone.
- Lock persistence.
- Target switch delay.
- Maximum correction angle.
- Priority weighting by distance, threat, and reticle proximity.
- Controller-specific multipliers.

## 9.3 Interaction

Use a single context action for:

- Doors.
- Switches.
- Terminals.
- Reading signs.
- Activating secret objects.
- Picking up the Golden Tennis Ball.

Interactions must show a short high-contrast prompt.

---

# 10. Input and Control Specification

## 10.1 Universal action layer

Gameplay code must reference named actions, never raw keys or button numbers:

- `move_forward`
- `move_backward`
- `strafe_left`
- `strafe_right`
- `look_left`
- `look_right`
- `look_up`
- `look_down`
- `fire_primary`
- `fire_secondary`
- `use`
- `jump`
- `run`
- `weapon_next`
- `weapon_previous`
- `pause`
- `menu_accept`
- `menu_back`

Implement an `InputProfile` resource with per-device bindings, dead zones, sensitivity, inversion, and curves.

## 10.2 Keyboard and mouse default

- WASD: move.
- Mouse: look.
- Left click: primary fire.
- Right click: alternate fire.
- E: use.
- Space: jump.
- Shift: run.
- Up/Down arrow keys cycle weapons; number keys select weapons directly.
- Escape: pause.

## 10.3 Flight-stick “Classic 1996” default

Designed for Thrustmaster USB Joystick 2960623:

- Stick X: turn left/right.
- Stick Y: move forward/back.
- POV left/right: strafe left/right.
- POV up/down: look up/down or previous/next weapon, selectable in setup.
- Trigger: primary fire.
- Button 2: use.
- Button 3: jump.
- Button 4: alternate fire.
- Remaining button: weapon cycle or run.
- Thumb throttle: movement-speed governor from walk to full run.

This mode assumes strong auto-aim.

## 10.4 Flight-stick “Hybrid” default

For players willing to use a keyboard with the stick:

- Stick X/Y: look.
- WASD: move.
- Trigger: primary fire.
- Stick buttons: use, jump, alternate fire, weapon cycle.
- Thumb throttle: weapon-select radial position or movement speed.

## 10.5 Remapping and calibration screen

Must include:

- Device dropdown.
- Live device name/GUID where available.
- Live axis bars.
- Live button indicators.
- Resting-axis calibration.
- Min/max axis calibration.
- Dead-zone slider per axis.
- Sensitivity slider.
- Linear/exponential response curve.
- Axis inversion.
- Bind-by-moving control workflow.
- Conflict detection.
- Reset to defaults.
- Save profile under `user://`.
- Keyboard-only escape path.

## 10.6 Input diagnostic mode

Launch with a debug flag or menu item:

`--input-diagnostics`

Display:

- Connected devices.
- Device index.
- Device name.
- GUID/mapping string where exposed.
- Raw axes and values.
- Raw buttons.
- Current action values.
- Active dead zones.
- Last input timestamp.
- Export-to-text report.

This is mandatory because physical Thrustmaster macOS compatibility cannot be proven in software development without the device.

---

# 11. Weapons

## 11.1 Pawstol

Starting weapon.

- Chunky semi-automatic sci-fi pistol.
- Infinite reserve or generous ammo.
- Strong muzzle flash.
- Readable recoil.
- High accuracy.
- Alt-fire: short three-shot “bark burst.”
- Cobie paw and jacket sleeve visible.

## 11.2 Barkshot

Close-range shotgun analogue.

- Wide spread.
- Strong knockback.
- Excellent sound and screen response.
- Breaks damaged walls and props.
- Alt-fire consumes two shells for tighter, heavier blast.

## 11.3 Fetch Launcher

Tennis-ball projectile launcher.

- Bouncing glowing ball projectile.
- Explodes after short delay or enemy contact.
- Can activate special ball-return secrets.
- Alt-fire recalls the latest ball toward Cobie, damaging enemies on return.

## 11.4 Weapon feel requirements

Each weapon needs:

- Distinct silhouette.
- Fire animation.
- Muzzle flash.
- Recoil.
- Sound layer.
- Impact effect.
- Enemy reaction.
- Ammo readout.
- Pickup model.
- Controller vibration only when supported; never required.

---

# 12. Enemies

## 12.1 Leash Enforcement Drone

Role: basic ranged enemy.

- Floating municipal drone.
- Red compliance light.
- Fires slow visible bolts.
- Strafes lightly.
- Announces bureaucratic warnings in text bleeps.
- Low health.

## 12.2 Mutant Groundskeeper

Role: melee pressure.

- Large sprite enemy with mower/blade equipment.
- Charges after short telegraph.
- Can be baited into hazards.
- Medium health.

## 12.3 Squirrel Trooper

Role: mobile harasser.

- Small, fast, erratic.
- Throws explosive acorns.
- Jumps between cover markers.
- Low health but difficult to track without auto-aim.

## 12.4 Elite: Compliance Hound

Role: fast miniboss.

- Robotic canine enforcer.
- Dash attack.
- Shield weak point.
- Drops armor.

## 12.5 Boss: Animal Control Walker

Role: arena finale.

Phases:

1. Mounted compliance cannons and drones.
2. Armor panels break.
3. Exposed core and charging melee attacks.
4. Golden Tennis Ball becomes interactable projectile.
5. Final hit triggers exaggerated explosion.

Boss must remain readable with flight-stick controls and strong auto-aim.

---

# 13. Pickups and Resources

- **Treats:** health.
- **Premium treats:** large health.
- **Leather padding:** armor.
- **Squeaky toy:** temporary enemy distraction.
- **Zoomies:** temporary speed and fire-rate boost.
- **Ammo boxes:** weapon-specific.
- **Golden tag:** score collectible.
- **Access collar:** keycard equivalent.
- **Water bowl:** full restore, one per level.

Pickup text should be short and funny.

Examples:

- “GOOD DOG. +10 HEALTH.”
- “TACTICAL SQUEAKER ACQUIRED.”
- “ZOOMIES ACTIVATED.”
- “THE JACKET COUNTS AS ARMOR.”

---

# 14. Level Design

## 14.1 Macro layout

### Zone A: Forbidden Field
Purpose:

- Tutorial through play.
- First weapon.
- First drones.
- First secret behind the “No Animals” sign.
- Exterior storm atmosphere.

### Zone B: Equipment Shed
Purpose:

- First locked door and switch.
- Barkshot acquisition.
- Breakable wall.
- Tight close-range encounter.

### Zone C: Maintenance Tunnels
Purpose:

- Introduce verticality, hazards, and Squirrel Troopers.
- Forked route.
- Secret water-bowl room.
- Industrial PNW mood.

### Zone D: Animal Compliance Lab
Purpose:

- Visual story reveal.
- Elite encounter.
- Fetch Launcher acquisition.
- Computer terminals and absurd policy signs.

### Zone E: Secret Dog Park
Optional:

- Requires observation or bouncing a Fetch Launcher projectile.
- High-value armor and joke payoff.
- Counts as one secret.

### Zone F: Walker Arena
Purpose:

- Boss.
- Golden Tennis Ball retrieval.
- Victory exit.

## 14.2 Secret design

At least three secrets:

1. Interact with the “No Animals” sign three times.
2. Break a suspiciously cracked maintenance wall.
3. Bounce a tennis ball into a “BALL RETURN” chute.
4. Optional fourth: follow paw-print decals backward.

Secrets must have:

- Discovery sound.
- On-screen label.
- Meaningful reward.
- Count in end-level summary.

## 14.3 Environmental humor examples

- “NO ANIMALS ON SPORTS FIELD.”
- “MUTANT-FREE ZONE” beside obvious mutants.
- “AUTHORIZED FETCHING ONLY.”
- “LEASH LENGTH SUBJECT TO ALGORITHMIC REVIEW.”
- “GOOD DOG STATUS: REVOKED.”
- “FETCH THIS!” boss-arena sign.
- Employee-of-the-month portrait of a vacuum cleaner.
- Compliance terminal: “JOY EVENT DETECTED. INCIDENT CREATED.”

---

# 15. Art Direction

## 15.1 Hero identity

Cobie must consistently retain:

- Apricot/golden curly labradoodle fur.
- Floppy ears.
- Black nose.
- Aviator sunglasses.
- Black leather jacket.
- Playful, confident energy.
- Dog tag labeled COBIE where visible.

## 15.2 Cover art

Use the generated cover as the initial brand reference.

Final production cover should eventually:

- Remove inaccurate Windows 95/98 platform labeling for the Mac release.
- Preserve the central heroic Cobie composition.
- Keep metallic gold title treatment.
- Use “Retro Mayhem 3D” as subtitle.
- Add a Mac/browser release badge rather than a copied retro platform mark.

## 15.3 In-game style

- 1990s pixel-art shooter energy.
- Original silhouettes.
- Low-resolution texture filtering disabled.
- Billboard sprites face the camera.
- Sprite animation at 6–12 FPS.
- World rendering may run at 60 FPS.
- Bold warm muzzle flashes against stormy gray-green PNW environments.
- Palette: asphalt gray, wet concrete, evergreen, safety yellow, amber explosions, leather black, Cobie gold.

## 15.4 Gore setting

Provide:

- Off.
- Cartoon debris.
- Retro exaggerated.

Default to cartoon debris. Enemies are primarily nonhuman robots and mutants.

---

# 16. Audio Direction

Music:

- Original industrial-metal/chiptune hybrid.
- One exploration loop.
- One combat layer.
- One boss track.
- No imitation of identifiable copyrighted themes.

Sound:

- Punchy weapon transients.
- Exaggerated shell/impact sounds.
- Dog-themed UI stings used sparingly.
- Strong pickup feedback.
- Distinct enemy telegraphs.

Voice:

- Minimal.
- Use original short Cobie barks, grunts, or synthesized non-identifiable vocalizations.
- Do not copy famous Duke Nukem lines or vocal delivery.
- Prefer on-screen quips.

Possible original quips:

- “Sign seems optional.”
- “Fetch was a warning.”
- “Who’s a good insurgent?”
- “That’s going in the incident report.”

---

# 17. UI and UX

## 17.1 Main menu

- New Game.
- Continue.
- Input Setup.
- Options.
- Credits.
- Quit on native build.

## 17.2 HUD

- Health.
- Armor.
- Ammo.
- Current weapon.
- Cobie portrait with damage states.
- Key/access item.
- Minimal crosshair.
- Optional auto-aim target hint.
- Secret notification.

## 17.3 End-level screen

Display:

- Completion time.
- Enemies defeated.
- Secrets found.
- Accuracy.
- Damage taken.
- Control method.
- Rank.

Ranks:

- Good Dog.
- Very Good Dog.
- Tactical Labradoodle.
- Unleashed.
- Cobie Nukem.

## 17.4 Accessibility

- Full key and controller remapping.
- Auto-aim strength.
- Subtitles/text equivalents.
- Reduced camera shake.
- Reduced flashes.
- Head bob off.
- Adjustable FOV.
- Hold/toggle run.
- Gore level.
- High-contrast interaction prompts.
- Master/music/SFX volume.
- Color should not be the only state indicator.

---

# 18. Technical Architecture

## 18.1 Repository structure

```text
cobie-nukem/
├── project.godot
├── export_presets.cfg
├── README.md
├── AGENTS.md
├── LICENSE
├── docs/
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── INPUT_COMPATIBILITY.md
│   ├── ART_DIRECTION.md
│   ├── LEVEL_DESIGN.md
│   ├── QA_PLAN.md
│   └── ASSET_MANIFEST.md
├── assets/
│   ├── brand/
│   ├── textures/
│   ├── sprites/
│   ├── models/
│   ├── audio/
│   ├── fonts/
│   └── shaders/
├── scenes/
│   ├── boot/
│   ├── menus/
│   ├── player/
│   ├── weapons/
│   ├── enemies/
│   ├── pickups/
│   ├── interactables/
│   ├── levels/
│   ├── ui/
│   └── debug/
├── scripts/
│   ├── core/
│   ├── input/
│   ├── player/
│   ├── combat/
│   ├── ai/
│   ├── save/
│   ├── ui/
│   └── debug/
├── resources/
│   ├── weapons/
│   ├── enemies/
│   ├── input_profiles/
│   └── balance/
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── smoke/
│   └── run_tests.gd
├── tools/
├── builds/
└── .github/
    └── workflows/
```

## 18.2 Core autoloads

- `GameState`
- `SettingsManager`
- `SaveManager`
- `InputManager`
- `AudioManager`
- `SceneRouter`
- `DebugLog`

Avoid global state beyond these explicit services.

## 18.3 Data-driven resources

Use custom Godot resources for:

- Weapon definition.
- Enemy definition.
- Pickup definition.
- Input profile.
- Auto-aim tuning.
- Difficulty tuning.
- Level metadata.

Balance changes should not require editing gameplay scripts.

## 18.4 Player architecture

`CharacterBody3D` root with:

- Movement controller.
- Camera pivot.
- Weapon mount.
- Health/armor component.
- Interaction ray.
- Auto-aim component.
- Inventory.
- Input adapter.
- Animation/effects coordinator.

## 18.5 Enemy architecture

Finite state machine:

- Idle.
- Alert.
- Chase.
- Attack.
- Hurt.
- Stunned.
- Dead.

Use navigation only where needed. Prefer simple authored routes and line-of-sight logic to reduce complexity.

## 18.6 Save system

Store under `user://`:

- Settings.
- Input profiles.
- Checkpoint.
- Best completion time.
- Secrets found.
- Last selected mode.

No personal data or network dependency.

---

# 19. Performance Requirements

## Native Mac target

On an M4 Mac mini:

- 60 FPS at 1920×1080 output with low-resolution internal viewport.
- Frame-time spikes below 33 ms during normal combat.
- Game launch to menu under 10 seconds.
- Level load under 10 seconds.
- Memory target below 1 GB.
- No persistent input lag attributable to polling.

## Web target

- Stable 30 FPS minimum on a current desktop browser.
- Prefer 60 FPS on modern Macs.
- Initial compressed download target under 150 MB.
- No threaded-export requirement for v1.
- Keyboard/mouse fully functional.
- Browser pause on focus loss.
- Audio begins only after user interaction.

---

# 20. Build, CI, and Hosting

## 20.1 Local commands

Document exact commands for:

- Import/check project headlessly.
- Run test suite.
- Launch game.
- Launch input diagnostics.
- Export macOS debug/release.
- Export web.
- Serve web build locally over HTTP/HTTPS-compatible tooling.

## 20.2 CI checks

On pull request:

- Validate project imports headlessly.
- Run script/static checks.
- Run custom headless unit tests.
- Instantiate critical scenes.
- Verify required assets exist.
- Verify no disallowed asset names or obvious copyrighted source files.
- Build web artifact.
- Build macOS ZIP where runner support is available.

On main:

- Produce versioned artifacts.
- Deploy web artifact to GitHub Pages.
- Create or update a prerelease artifact.
- Do not attempt notarization without secrets.

## 20.3 Hosting

Primary web host:

- GitHub Pages through GitHub Actions.

Optional showcase host:

- itch.io upload after the first stable vertical slice.

Native build:

- GitHub Releases.
- Optional itch.io download.

---

# 21. Testing Strategy

## 21.1 Automated tests

At minimum:

- Damage and armor math.
- Ammo consumption.
- Weapon cooldowns.
- Pickup behavior.
- Save/load round trip.
- Input-profile serialization.
- Dead-zone function.
- Response-curve function.
- Auto-aim target filtering.
- Enemy state transitions.
- Secret counting.
- Level exit conditions.
- Required scene instantiation.

## 21.2 Headless smoke tests

- Boot to menu.
- Load level.
- Spawn player.
- Spawn each weapon.
- Spawn each enemy.
- Simulate damage.
- Trigger checkpoint.
- Trigger victory.
- Validate export presets.

## 21.3 Manual tests

- Full keyboard/mouse playthrough.
- Full flight-stick playthrough after hardware arrives.
- Unplug/replug joystick.
- Remap every action.
- Deliberately create axis drift and calibrate it out.
- Web playthrough in Chrome and Safari.
- Test with no controller connected.
- Test at 16:9 and ultrawide.
- Test pause/focus loss.
- Test reduced-flash and reduced-shake modes.

---

# 22. Asset and IP Rules

Allowed:

- Original user-provided Cobie photographs.
- Generated original Cobie art.
- Procedurally generated geometry.
- Original code.
- CC0 and permissively licensed assets with attribution where required.
- Original or properly licensed fonts and audio.

Disallowed:

- Duke Nukem game files.
- Extracted sprites, textures, maps, music, sounds, logos, or dialogue.
- Trace-over recreations of official cover art.
- Famous voice-line imitations.
- Unlicensed commercial asset-pack redistribution.
- “Temporary” copyrighted assets committed to the repository.

Maintain `docs/ASSET_MANIFEST.md` with source, license, modifications, and file path.

---

# 23. Milestones

## Milestone 0: Repository and proof of life

- Godot 4.7 project boots.
- Graybox room.
- Mouse/keyboard movement.
- One target can be shot.
- Headless project check.
- CI baseline.

## Milestone 1: Input-first prototype

- Universal action layer.
- Keyboard/mouse profile.
- Flight-stick profiles.
- Diagnostics screen.
- Calibration/remapping.
- Saved input settings.
- Auto-aim prototype.

## Milestone 2: Combat sandbox

- Three weapons.
- Two enemy types.
- Pickups.
- Damage, armor, death, restart.
- Weapon feel pass.

## Milestone 3: Full graybox level

- Entire level traversable.
- Doors, keys, switches.
- All encounters.
- Boss graybox.
- Secrets functional.
- Start-to-finish completion.

## Milestone 4: Cobie identity and art pass

- Cobie HUD portrait.
- Paw/jacket weapon presentation.
- Sprite enemies.
- Retro render pipeline.
- Signs and environmental jokes.
- Cover/title integration.

## Milestone 5: Audio, polish, and balance

- Music and SFX.
- Hit feedback.
- Difficulty tuning.
- Accessibility.
- Complete menus.
- Score/rank screen.

## Milestone 6: Release candidate

- Native Mac export.
- Web export.
- GitHub Pages deployment.
- Full test pass.
- Hardware test checklist ready.
- Known-issues document.
- Downloadable build.

---

# 24. Definition of Done

The vertical slice is complete when:

1. A new user can launch it on an Apple-silicon Mac.
2. The game is finishable from title screen to victory.
3. First playthrough lasts approximately 12–20 minutes.
4. It contains three weapons, three regular enemies, one elite, and one boss.
5. It contains at least three discoverable secrets.
6. Keyboard/mouse is polished.
7. Flight-stick mapping, diagnostics, calibration, and remapping exist.
8. Physical Thrustmaster support is honestly labeled unverified until tested.
9. Browser build is playable with keyboard/mouse.
10. Native macOS build is the recommended joystick version.
11. Art, audio, and code provenance is documented.
12. No Duke Nukem assets or copied dialogue appear.
13. Automated tests pass.
14. Headless import/export checks pass.
15. README includes setup, build, controls, hosting, and hardware-test instructions.
16. The game feels recognizably about Cobie, not merely a generic FPS.
17. The opening sign joke and final Golden Tennis Ball payoff are present.
18. The cover art appears in the title/landing presentation.
19. The repository is clean enough for another Codex session to continue without reconstruction.
20. Known limitations are documented without pretending unresolved hardware compatibility is solved.

---

# 25. Risks and Mitigations

## Risk: Budget joystick is not recognized correctly by macOS

Mitigation:

- Raw input diagnostics.
- Full remapping.
- No reliance on manufacturer configuration software.
- Keyboard/mouse fallback.
- Hyperkin compatibility-safe fallback.
- Native build prioritized over browser.
- Hardware acceptance checklist.

## Risk: Codex produces breadth without game feel

Mitigation:

- Milestone 2 dedicated to movement and weapons.
- Quantified tuning variables.
- Require playable builds after each milestone.
- Do not polish art before combat sandbox is fun.

## Risk: Browser export becomes a time sink

Mitigation:

- Single-threaded web export.
- Compatibility renderer.
- Small assets.
- Keyboard/mouse as browser baseline.
- Native build remains canonical.

## Risk: Too much scope

Mitigation:

- One level.
- Three weapons.
- Three regular enemies.
- No multiplayer.
- Procedural/placeholders permitted until full graybox is complete.

## Risk: Working title is too derivative for public commercial use

Mitigation:

- Treat as private prototype.
- Keep all assets original.
- Add a rename gate before public monetization or marketing.

---

# 26. One-Shot Codex Goal Prompt

Copy everything below into Codex after creating or selecting an empty GitHub repository and placing the PRD in `docs/PRD.md`.

---

## CODEX GOAL PROMPT

You are the lead autonomous engineer, technical director, and integration owner for a complete Godot game vertical slice.

Your goal is to build a genuinely playable, polished macOS-first retro FPS called **Cobie Nukem: Retro Mayhem 3D**, based on the complete requirements in `docs/PRD.md`.

Do not stop after scaffolding, documentation, isolated prototypes, or a graybox unless a hard environment limitation makes continued work impossible. Continue through implementation, testing, integration, exports, and a playable start-to-finish vertical slice.

### Product intent

Build a compact original retro FPS specifically designed around:

- A heroic labradoodle named Cobie wearing aviator sunglasses and a black leather jacket.
- Flight-stick controls with exaggerated auto-aim.
- Full mouse/keyboard compatibility.
- Secrets, environmental humor, chunky weapons, fast movement, and 1990s shooter energy.
- A native macOS build as the canonical flight-stick experience.
- A browser-playable vertical slice as a secondary build.
- One complete 12–20 minute level.
- Original assets and code only.

The opening must use the “NO ANIMALS ON SPORTS FIELD” joke. The story must culminate in Cobie recovering the Golden Tennis Ball and defeating the Animal Control Walker.

### Source of truth

1. Read `docs/PRD.md` completely.
2. Treat it as the product and acceptance-criteria source of truth.
3. Inspect the repository, toolchain, operating system, installed Godot version, available assets, and GitHub configuration before changing files.
4. Pin Godot **4.7 stable** unless the repository already contains a deliberate, documented compatible pin.
5. Use the standard Godot build and **GDScript**, not C#.
6. Use the Compatibility renderer and a low-resolution internal viewport.
7. If a provided cover image exists, integrate it from `assets/brand/cobie_nukem_cover.png`. If absent, create a clearly labeled placeholder and continue; do not block.
8. Never use or fetch Duke Nukem assets, maps, sounds, music, dialogue, logos, or extracted game files.

### Autonomous working behavior

- Make reasonable product and technical decisions without waiting for approval.
- Ask a question only when a missing credential, destructive ambiguity, or unavailable external resource truly blocks progress.
- Do not fabricate successful hardware testing.
- Physical Thrustmaster USB Joystick compatibility cannot be marked verified without the device.
- Build the complete diagnostics, calibration, remapping, and acceptance-test workflow regardless.
- Keep the project runnable after each milestone.
- Commit coherent milestones with descriptive messages.
- Maintain `docs/DECISIONS.md` for material deviations from the PRD.
- Maintain `docs/KNOWN_ISSUES.md`.
- Maintain `docs/ASSET_MANIFEST.md`.
- Prefer simple, robust systems over clever abstractions.

### Required subagent strategy

Immediately create an execution plan and spin up specialized subagents or parallel workstreams to increase throughput. Use separate branches/worktrees or clearly separated directory ownership to avoid merge collisions.

Use at least these workstreams:

1. **Architecture and Build Agent**
   - Repository structure.
   - Godot configuration.
   - autoloads.
   - export presets.
   - CI.
   - headless checks.
   - macOS and web builds.

2. **Player, Movement, and Combat Agent**
   - CharacterBody3D controller.
   - movement feel.
   - health/armor.
   - weapons.
   - impacts.
   - pickups.
   - death/restart.

3. **Input and Joystick Agent**
   - universal action layer.
   - keyboard/mouse.
   - flight-stick profiles.
   - SDL/Godot device handling.
   - raw diagnostics.
   - calibration.
   - dead zones.
   - curves.
   - remapping.
   - persistence.
   - browser limitations.

4. **Enemy and Boss Agent**
   - enemy state machines.
   - three regular enemies.
   - elite Compliance Hound.
   - Animal Control Walker boss.
   - telegraphs and auto-aim-friendly behavior.

5. **Level Design and Narrative Agent**
   - complete graybox.
   - pacing.
   - doors, switches, keys.
   - secrets.
   - environmental jokes.
   - opening and ending.
   - boss arena.

6. **Art, UI, and Retro Rendering Agent**
   - low-resolution viewport.
   - pixel scaling.
   - billboard sprites.
   - HUD.
   - menus.
   - Cobie identity.
   - signs.
   - title and cover integration.
   - accessibility visuals.

7. **Audio and Feedback Agent**
   - original or permissively licensed audio.
   - music placeholders if necessary.
   - weapon sound layering.
   - pickup/secret stings.
   - hit feedback.
   - asset provenance.

8. **QA and Integration Agent**
   - automated tests.
   - headless smoke tests.
   - scene-instantiation tests.
   - performance checks.
   - manual QA checklist.
   - release validation.

Each subagent must return:

- Files changed.
- Tests run.
- Results.
- Remaining risks.
- Integration notes.

The lead agent must review and integrate all work. Do not accept subagent claims without running the relevant tests in the integrated branch.

### Coordination rules

- Establish interfaces before parallel implementation.
- Give agents directory ownership where possible.
- Avoid two agents rewriting `project.godot`, autoload configuration, or shared core scripts simultaneously.
- Architecture agent owns project configuration.
- Input agent owns `scripts/input`, `scenes/debug`, and input resources.
- Combat agent owns player and weapon systems.
- Enemy agent owns enemy and boss systems.
- Level agent owns level scenes after shared interfaces stabilize.
- UI agent owns menus/HUD and rendering presentation.
- QA agent may add tests but should not rewrite production architecture without lead review.
- Rebase or merge frequently.
- Resolve conflicts by preserving tested behavior and PRD acceptance criteria.

### Implementation order

#### Phase 0: Inspect and plan

- Verify repository state.
- Verify Godot availability.
- Create `docs/IMPLEMENTATION_PLAN.md`.
- Create task graph with dependencies.
- Record baseline commands.
- Create or update `AGENTS.md` with repository conventions.
- Launch subagents.

#### Phase 1: Proof of life

- Project boots.
- Graybox room.
- Player moves with mouse/keyboard.
- One weapon hits one target.
- Headless import works.
- CI baseline passes.

#### Phase 2: Input-first foundation

- Named action layer.
- Input profiles.
- flight-stick Classic 1996 mode.
- hybrid mode.
- diagnostics scene.
- axis/button visualization.
- calibration.
- dead zones and curves.
- rebinding.
- profile persistence.
- keyboard escape path.
- auto-aim prototype.

The target budget device is the Thrustmaster USB Joystick model 2960623:

- three axes.
- four buttons plus trigger.
- thumb throttle.
- USB-A connection.
- target price about $25.
- current manufacturer platform guarantee is PC, not general macOS.
- therefore implement generic configurable input and label physical Mac verification pending.
- M4 Mac mini users require a USB-A-to-USB-C adapter or hub.

#### Phase 3: Combat sandbox

- Tune movement.
- Implement Pawstol, Barkshot, and Fetch Launcher.
- Implement health, armor, ammo, pickups.
- Implement two enemies.
- Add hit feedback.
- Make the sandbox fun before proceeding.

#### Phase 4: Complete graybox

- Build the full level from sports field to boss arena.
- Add all gates, switches, key items, secrets, checkpoint, and victory.
- Implement all enemies and boss.
- Ensure the level is finishable from a clean launch.

#### Phase 5: Cobie and retro presentation

- Integrate Cobie’s visual identity.
- Add HUD portrait and paw/jacket weapon presentation.
- Add sprite enemies.
- Add low-resolution rendering and nearest-neighbor scaling.
- Add signs and environmental jokes.
- Add title sequence and cover art.
- Add menus and settings.

#### Phase 6: Audio and polish

- Add original/permissive audio.
- Tune effects, recoil, feedback, encounters, and boss readability.
- Add accessibility settings.
- Add end-level score and ranks.
- Optimize native and web performance.

#### Phase 7: Test and release

- Run all automated and headless tests.
- Perform full keyboard/mouse playthrough.
- Build macOS `.app`/`.zip`.
- Build web export.
- Deploy web build through GitHub Pages if repository permissions allow.
- Produce release notes and known issues.
- Do not claim joystick hardware verification without physical test results.
- Include exact hardware test instructions.

### Technical requirements

- Godot 4.7 stable.
- Standard build and GDScript.
- Compatibility renderer.
- 320×180 default internal resolution.
- Nearest-neighbor integer scaling.
- Native 60 FPS target on M4 Mac mini.
- Web 30 FPS minimum.
- Data-driven weapon, enemy, auto-aim, and input resources.
- `user://` persistence.
- No required online services.
- No telemetry.
- No accounts.
- No paid runtime APIs.
- No server component.
- No C# because Godot 4 web export is required.

### Input requirements

Implement:

- Named actions only in gameplay code.
- Keyboard/mouse defaults.
- Classic flight-stick mode.
- Hybrid stick/keyboard mode.
- Generic gamepad support.
- Full remapping.
- Per-axis dead zones.
- Per-axis inversion.
- Sensitivity.
- response curves.
- live diagnostics.
- device reconnect handling.
- profile persistence.
- auto-aim Off/Light/Classic/Heavy.

Browser controller support must be labeled experimental and must never prevent keyboard/mouse play.

### Quality gates

Do not advance a milestone until:

- Project imports without parser errors.
- Critical scenes instantiate.
- Relevant automated tests pass.
- The build is playable.
- Documentation reflects reality.
- No copyrighted source assets were added.
- No unresolved errors are hidden or silently ignored.

### Test commands and evidence

Create reproducible commands for:

- headless import.
- test runner.
- native launch.
- diagnostics launch.
- macOS export.
- web export.
- local web serve.

At the end of each milestone, record:

- command.
- exit result.
- relevant output.
- artifact path.
- known issues.

### Final deliverables

The repository must end with:

- Complete Godot source.
- One playable 12–20 minute level.
- Three weapons.
- Three regular enemies.
- One elite.
- One boss.
- Three or more secrets.
- Full menus and HUD.
- Keyboard/mouse support.
- flight-stick profiles.
- diagnostics/calibration/remapping.
- macOS build artifact.
- web build artifact.
- GitHub Pages workflow.
- automated tests.
- complete README.
- architecture notes.
- input compatibility guide.
- QA plan.
- asset manifest.
- known issues.
- release notes.
- clear physical joystick verification checklist.

### Completion standard

The result must feel like a small finished game, not a technical demo.

Prioritize, in order:

1. A complete playable loop.
2. Movement and weapon feel.
3. Reliable input abstraction.
4. Readable encounters.
5. Cobie-specific humor and identity.
6. Testing and exports.
7. Additional polish.

When faced with scope pressure, cut secondary polish before cutting completeness, input reliability, or the final boss.

Begin now by inspecting the repository, reading the PRD, creating the implementation plan, defining subagent ownership, and producing the first runnable proof of life.

---

# 27. Owner Hardware Test Procedure

After purchasing the joystick:

1. Connect it through a USB-A-to-USB-C adapter or hub.
2. Launch the native macOS build.
3. Open **Input Setup → Diagnostics**.
4. Press every button.
5. Move stick X and Y to full extremes.
6. Move the thumb throttle end to end.
7. Move the POV control in every direction.
8. Run auto-calibration.
9. Save the profile.
10. Play the entire level in Classic 1996 mode.
11. Unplug/replug the joystick and confirm recovery.
12. Export the diagnostics report.
13. Mark the tested device, adapter, macOS version, game version, and results in `docs/INPUT_COMPATIBILITY.md`.

Only after these steps should the README say the exact hardware combination is verified.
