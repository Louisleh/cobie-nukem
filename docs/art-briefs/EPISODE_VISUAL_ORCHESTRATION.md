# Episode 1 visual orchestration — L1→L5 cohesion, checklist, and ImageGen kit

**Who this is for:** the human owner + ChatGPT/ImageGen (concepts) + Blender (final renders) +
Codex (integration). This is the **orchestrator and to-do list** that sits on top of
`docs/ART_BIBLE.md` (global law) and the per-mission briefs in this folder. It exists to keep
**Levels 1–5 reading as one game**: same hero, same weapons, same HUD, same enemy "faction,"
with only the *environment* and a few *new faction members* changing per level.

Read order for any art task: this file → `docs/ART_BIBLE.md` → the mission's
`*.yaml` brief → `.agents/skills/cobie-visual-foundry/SKILL.md`.

> **Pipeline reality:** ImageGen (ChatGPT/DALL·E) produces **concepts and reference sheets
> only**. Per the visual-foundry skill, **Blender owns the final deterministic directional
> renders, camera, lighting, orientation, and atlas packing**; Material Maker owns surfaces.
> Do not ship an uncontrolled ImageGen atlas as a final asset — it will fail the scale/feet/
> alpha contract and provenance. ImageGen sets the look; Blender makes it reproducible.

---

## 1. The one-game cohesion contract (every prompt inherits this)

These parameters are **identical for every character/enemy asset in all five levels**. If two
prompts disagree on any line here, the game stops looking like one game. Paste the "STYLE
PREAMBLE" in §6 into every ImageGen request.

- **Style:** high-resolution retro 2.5D — illustrated / pre-rendered 3D look, clean readable
  shapes, modern anti-aliased edges. **Not pixel art. Not photoreal.** (Locked by decision
  D-014.)
- **Camera for directional sprites:** orthographic, slight high 3/4 downward tilt, 8 evenly
  spaced yaw octants (front, front-right, right, back-right, back, back-left, left,
  front-left) in that fixed order.
- **Atlas layout:** one fixed **8 columns × 4 rows** sheet. Row 0 idle (8 directions), row 1
  locomotion-A (8 dir), row 2 locomotion-B (8 dir), row 3 reactions in fixed column order:
  `alert, telegraph, attack, hurt, stagger, milestone/phase, death` (+1 spare). Cell size
  **192×256** → sheet **1536×1024**. (Simpler support units may be **mesh-primary**, no
  atlas — see §3.)
- **Feet baseline & scale (critical):** every frame shares **one feet baseline** and
  consistent transparent padding. Record opaque subject height in px and the intended world
  height in metres; Godot uses `Sprite3D.pixel_size = intended_world_height /
  opaque_frame_height`. **Never eyeball scale per device.** This is the contract whose
  absence caused the tiny-robot-dog and tiny-boss bugs.
- **Background:** fully transparent (alpha) or a flat pure-magenta chroma key for local
  matte/despill. No baked ground, shadow blob, text, or frame.
- **Lighting (neutral for atlas):** even, slightly top-left key so the in-engine lighting
  reads correctly in every biome. **Do not bake biome light** (no orange sunset, no blue
  snow bounce) into a character atlas — the level lights it. Biome flavor on a recurring
  enemy is a thin *material overlay* (snow rime, salt, vacuum seals), not a relight.
- **Color language (identical everywhere):** warm **red/orange = enemy threat & telegraph**;
  **cyan = technological weak point / recoverable system**; **tennis-ball gold = progression,
  secrets, reward**; **municipal teal = the enforcement faction's body color**; pale cream /
  cool teal = friendly/assist info. Never communicate state by hue alone.
- **Shape language:** **Cobie & friendly/progression = rounded, warm, energetic.**
  **Compliance enemies = boxes, clamps, warning stripes, rigid shields, lenses, officious
  symmetry.** A new enemy must read as the same *faction* as the Squirrel Trooper and
  Compliance Hound, just adapted to its biome.

---

## 2. The persistent kit — DO NOT redesign per level

The owner's rule: **weapons and key characteristics stay the same level-to-level unless a
change adds clear value; early on, keep them the same.** These assets are authored **once** and
reused across all five missions. Changing any of them is a deliberate, owner-approved decision,
not per-level busywork.

| Asset | What it is | Rule across L1–L5 |
| --- | --- | --- |
| **Cobie** (HUD portrait set, cover, victory) | The hero labradoodle | Identical everywhere. Portrait currently ships two states `healthy / critical` (a mid `hurt` frame is optional, not currently used). |
| **Pawstol** | Weapon 1 view model (`assets/models/weapons/pawstol_viewmodel.glb`) | Identical in every level. Same model, muzzle flash, and projectile look. |
| **Barkshot** | Weapon 2 view model (`barkshot_viewmodel.glb`) | Identical in every level. |
| **Fetch Launcher** | Weapon 3 view model (`fetch_launcher_viewmodel.glb`) + Fetch projectile | Identical in every level. The Municipal Recall Override upgrade may add an FX tint, not a new model. |
| **HUD / crosshair / touch controls / weapon overlay** | `scenes/ui/*`, touch buttons | Identical layout, states, and iconography in every level; only safe-area adapts. |
| **Pickups** | treat, premium treat, water bowl, shells, tennis balls, squeaker, zoomies, access collar, golden tag, leather padding | Identical everywhere. A pickup means the same thing in every biome. |
| **Golden Tennis Ball** | Progression/reward accent | Identical gold, glow, and pop everywhere. The one sacred continuity object. |
| **Core compliance enemies** | Squirrel Trooper, Leash Enforcement Drone, Mutant Groundskeeper, Compliance Hound (elite), Compliance Gull, Umbrella Shield Enforcer | Reused as-is where they appear in later levels. At most a **thin biome overlay** (snow rime on the hound, salt on the gull) — never a redesign. |

**Weapons are inherently consistent** because they're the same GLB files — the job is to make
sure **every new enemy/prop is lit and shaded to match the existing weapon/enemy style**, not
to touch the weapons. If a later level ever *earns* a weapon variant (e.g. a Moon vacuum-sealed
Fetch Launcher), that is a scoped design decision recorded in the ART_BIBLE first — default is
**no change**.

---

## 3. The compliance-faction design system (how new enemies stay cohesive)

Every enforcement enemy in the game is a member of one faction. A new L3/L4/L5 enemy is
**"same faction, new biome + new job,"** never a fresh art style. Shared DNA:

- **Body color:** municipal teal (cool) as the base; sun-fade/frost/vacuum weathering per biome.
- **Warning system:** red/orange hazard stripes + a red telegraph light that flares on the
  `telegraph`/`attack` reaction frames.
- **Weak point:** one obvious **cyan** lens/core/vent, usually rear or exposed-after-commit.
- **Officious detailing:** clamps, citation printers, lenses, antenna, rigid symmetry, a badge
  or municipal seal.
- **Silhouette job:** each new enemy must be distinct *in silhouette* from its levelmates —
  vary height/width/stance (tall thin turret vs. wide low tank vs. small fast flyer) so a group
  reads instantly. See each brief's `silhouette_goal` and `enemy_roster`.

Biome overlays (thin, additive): **Mount Hood** = frost rime + snow-pack on treads; **Moon** =
vacuum seals, antenna, hard rim-light-friendly panels; **Ventura** = salt corrosion + sun-fade.

---

## 4. Per-level asset checklist (the to-do list)

Status legend: **✅ exists** · **♻ reuse as-is** · **♻+ reuse + thin biome overlay** ·
**🆕 new this level (ImageGen→Blender)** · **🎛 mesh-primary (Codex/Blender, no ImageGen atlas)**.

### Persistent kit (build/confirm once, before L3 art starts)
- [ ] ✅ Cobie portraits — ships two states `healthy / critical` (`assets/ui/portraits/`). A
      mid `hurt` frame is optional and not currently wired; add only if the owner wants a
      three-step damage read.
- [ ] ✅ Weapons: Pawstol / Barkshot / Fetch Launcher view models + Fetch projectile.
- [ ] ✅ HUD, crosshair, weapon overlay, touch controls.
- [ ] ✅ Pickups (10) + Golden Tennis Ball.

### L1 — Salmon Creek (shipped; reference standard)
- [ ] ✅ Enemy atlases: Squirrel Trooper, Leash Enforcement Drone, Mutant Groundskeeper,
      Compliance Hound (8×4), Animal Control Walker boss (8×4).
- [ ] ✅ Surface kit: wet turf, utility concrete, lab panels, arena plating (512²).
- [ ] Action: **treat these as the canonical style target** — every new enemy/texture is
      color-matched and shading-matched to these.

### L2 — Rain City / Vancouver (in production)
- [ ] ♻ Reused: Squirrel, Drone, Mutant, Hound.
- [ ] ✅/🆕 New this level: Compliance Gull (🎛 mesh), Umbrella Shield Enforcer, Municipal
      Towmaster convoy boss.
- [ ] 🆕 Surface kit: wet asphalt, seawall concrete, harbour steel, brick, glass, restaurant
      tile, terminal flooring, painted vehicle metal (Material Maker).
- [ ] Action (from the L2 QA report): remove/replace the flat "hot air duct" hazard slabs;
      those violate the ART_BIBLE ban on invisible-damage slabs.

### L3 — Mount Hood (active; brief: `mount_hood_summit.yaml`)
- [ ] ♻ Reused: Squirrel, Drone, Mutant, Hound (♻+ optional frost overlay on the Hound).
- [ ] 🆕 **Ski-Patrol Ranger** — RANGED hero atlas (8×4). Intended height ~1.75 m.
- [ ] 🆕/🎛 **Snowcat Plow Tank** — TANK / mini-boss. Start mesh-primary; graduate to atlas.
      Intended height ~2.6 m.
- [ ] 🎛 **Avalanche Recon Drone** — FLYING/SUPPORT, mesh-primary (Gull-style). ~0.9 m.
- [ ] 🆕 Boss/set piece: **Summit Relay** — reuse the MovingSetPiece + multi-phase boss
      vocabulary (no bespoke fork); cyan beacon-dish weak points.
- [ ] 🆕 Surface kit: packed-snow (traction), loose-powder (slip), groomed corduroy slope,
      faceted alpine rock, lodge timber, fieldstone, frost-rimed service metal, warming-shelter
      ember (Material Maker).
- [ ] 🆕 Landmark models: timber lodge A-frame, chairlift line/towers, snowcat groomer, ridge.

### L4 — Moon (brief: `moon_fetch.yaml`)
- [ ] ♻/♻+ Reused: a subset of core enemies as "vacuum-sealed" variants where it fits.
- [ ] 🆕 **Vacuum Recon Drone** — FLYING hero atlas (8×4). ~1.1 m.
- [ ] 🎛 **Constellation Support Node** — SUPPORT, mesh-primary. ~0.8 m.
- [ ] 🆕 Boss: **Earthrise Compliance Engine** — crater-scale, reuse boss vocabulary.
- [ ] 🆕 Surface kit: lunar regolith, crater-rim rock, pressurized habitat panel, hard exterior
      hull, observatory glass/systems, amber/black hazard-stripe edge decals.
- [ ] 🆕 Landmark: **Earth marble** skybox element (cheapest highest-impact asset — do first),
      modular habitats, observatory dish, lander.

### L5 — Ventura Pier (design-gated; brief: `ventura_pier.yaml`)
- [ ] ⚠ **Blocked on owner design ratification** (route/mechanic/enemy/boss are proposals).
      Palette/material/silhouette are safe to explore.
- [ ] 🆕 (proposed) Beach Patrol Skirmisher, Meter Enforcement Tank, Lifeguard Compliance Tower.
- [ ] 🆕 (proposed) Boss: Pier Citation Crane.
- [ ] 🆕 Surface kit: dry sand, wet tide sand, promenade concrete, faded boardwalk timber,
      salt-rimed marine steel, barnacled piling.
- [ ] 🆕 Landmark: pier over surf, boardwalk row, marina cranes, setting sun.

---

## 5. Continuity table — what recurs, what varies, when to vary

| Element | Recurs identically | Varies per level | Vary only if… |
| --- | --- | --- | --- |
| Cobie, weapons, HUD, crosshair, touch, pickups, Golden Ball | ✅ always | — | a variant is owner-approved and recorded in ART_BIBLE first |
| Core compliance enemies | ✅ reused | thin biome overlay only | a redesign demonstrably improves readability |
| Faction design DNA (teal/red-telegraph/cyan-weak-point/officious) | ✅ always | — | never |
| Environment kit, ground/surface textures, landmarks | — | ✅ every level (that's the identity) | — |
| New faction enemies (2–3/level) | — | ✅ new, but same faction DNA | — |
| Boss / signature set piece | — | ✅ new per level | must reuse MovingSetPiece + boss vocabulary, not fork |
| Lighting/fog treatment | — | ✅ per biome identity | must keep threats one value step off background |

**Default answer to "should this change between levels?" is NO.** The game feels cohesive
*because* the cast, kit, and rules are constant and only the *place* changes.

---

## 6. ImageGen kit (concepts / reference sheets)

### 6a. STYLE PREAMBLE — prepend to EVERY character/enemy request
```
Original game concept art for "Cobie Nukem," a high-resolution retro 2.5D action-comedy
shooter. Illustrated / pre-rendered 3D look with clean readable shapes and modern smooth
edges — NOT pixel art, NOT photorealistic. Orthographic view, slight high 3/4 downward
angle. Neutral even top-left studio lighting (no colored environment light baked in).
Fully transparent background, no ground, no shadow, no text, no frame, no logo.
Color language: municipal teal body for enforcement machines; warm red/orange warning
stripes and telegraph lights; a single cyan glowing weak point; tennis-ball gold reserved
for heroes/rewards. Officious, boxy, symmetrical "compliance bureaucracy" machine design
with clamps, lenses, warning decals, and a small municipal seal. 100% original — no
existing game characters, franchises, brands, celebrities, or logos.
```

### 6b. DIRECTIONAL SHEET template (for a hero enemy that needs the 8×4 atlas)
```
[STYLE PREAMBLE]
Subject: <ENEMY NAME> — <one-line silhouette from the brief>.
Produce a reference sheet of the SAME character in 8 evenly rotated views (front,
front-right, right, back-right, back, back-left, left, front-left), plus a second row of
reaction poses: alert, telegraph (warning light flaring), attacking, hurt, staggered,
phase/milestone, and death. Keep the character's proportions, colors, and the feet-line
IDENTICAL across every view and pose. Full-body, standing on an invisible common ground
line, consistent size in every cell. <biome overlay note>. <weak-point note>.
```
> ImageGen is for the **concept/turnaround reference**. Blender then rebuilds the model and
> renders the deterministic 8-direction atlas at 192×256 cells with the exact feet baseline.

### 6c. Worked example — Mount Hood **Ski-Patrol Ranger**
```
[STYLE PREAMBLE]
Subject: "Ski-Patrol Ranger" — an upright bipedal municipal enforcement ranger, ski-patrol
rescue-cross plate on the chest, cold cyan goggle band, a flare/ice-dart launcher held
across the body, rigid officious posture; boxy municipal shoulders. Cold teal shell with
frost-white trim and a red rescue-cross; the goggle lens is the cyan weak point; a red
muzzle light is the attack telegraph. Snowbound-alpine weathering: light frost rime on the
shoulders and boots. 8-direction turnaround + reaction row as specified. Intended in-game
height ~1.75 m; keep the feet line identical in every cell.
```

### 6d. Worked example — Moon **Vacuum Recon Drone**
```
[STYLE PREAMBLE]
Subject: "Vacuum Recon Drone" — a compact hovering municipal intake unit: rounded-box body,
a downward vacuum maw, one large cyan sensor eye (the weak point), short amber warning fins;
no legs, it floats. Vacuum-sealed lunar detailing: panel seams with faint cyan glow, a small
antenna. The intake maw glows red as the attack telegraph. Because it hovers, show the same
body in 8 rotations with a consistent hover height instead of a feet line. Intended in-game
height ~1.1 m.
```

### 6e. SURFACE / TEXTURE prompts (tiling — but Material Maker is the source of truth)
Use ImageGen only for a **look reference**; author the real tiling map in Material Maker so it
tiles seamlessly and exports Web-safe albedo/normal/ORM. Reference-prompt shape:
```
Seamless tileable PBR texture reference, top-down, flat even light, no baked shadows, no
props, no text: <e.g. "packed alpine snow with faint compression and micro-sparkle, cold
blue-white, subtle wind ripple">. Must read by value and micro-normal, not busy albedo.
```
Do **not** bake tracks, paw prints, tide lines, field paint, or unique grime into a tiling
base — those are separate decal layers (ART_BIBLE rule).

### 6f. NEGATIVE / avoid list (every prompt)
`pixel art, low-res, dithering, photorealism, real photographs, existing video-game
characters, franchise mascots, real brand logos, celebrity likeness, baked text/watermark,
baked drop shadow or ground, colored environment lighting on character sheets, uneven scale
between poses, inconsistent feet line.`

---

## 7. Orchestration sequence & acceptance gates

**Order of operations (so cohesion is locked before breadth):**
1. **Confirm the persistent kit** (§2) is complete and is the color/shading target — including
   the missing `cobie_hurt` check. Nothing new should out-style the weapons/HUD/existing enemies.
2. **Per active level (L3 first):** environment surface kit + landmark first (defines identity),
   then the hero readability enemy, then the tank/mini-boss, then the mesh support unit, then the
   boss set piece (reusing the shared vocabulary).
3. **For each asset:** ImageGen concept → Blender deterministic source/render (or Material Maker
   for surfaces) → Godot import → **scale/feet/silhouette contract** → four-aspect + 1024×768
   tablet captures → ASSET_MANIFEST entry + hash → `tools/asset_ip_scan.sh` green.
4. **Human review** owns taste, humor, comfort, photosensitivity, and "is this clearly one game."

**A new asset is done only when:** it imports clean; its rendered silhouette matches its
collision + intended threat (no tiny cell, no full-sheet reaction); it reads at tablet size and
combat distance; it stays one value step off its background; it has provenance + hash; and it
sits believably next to the L1 Salmon Creek assets in a side-by-side.

**Hard "stop and ask the owner" triggers:** any change to a persistent-kit asset (§2); any
Ventura production before its design is ratified; any enemy that reads as a different art style
than the existing faction; any hazard rendered as a flat slab with invisible damage.
