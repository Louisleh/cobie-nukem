# Opus 5 Handoff — Cobie Nukem Rain City Visual and Feel Uplift

**Status:** Execution brief for one bounded vertical-slice pilot  
**Prepared:** 2026-07-26  
**Repository:** `/Users/orion/Desktop/Hermes Files/projects/cobie-nukem`  
**Program branch:** `hermes/world-class-369-buildout`  
**Target gameplay baseline:** `d3de4de` (`docs: record WCB-008I integration evidence`)  
**Project authority:** `AGENTS.md`, `docs/PRD.md`, `docs/IMPLEMENTATION_PLAN.md`, and `docs/WORLD_CLASS_BUILDOUT_LOG.md` override this handoff if they conflict.

---

## Operator launcher

After Claude OAuth login, start Claude Code at the repository root using **Claude Opus 5 at maximum effort**, then provide this instruction:

> Read `docs/handoffs/OPUS5_RAIN_CITY_VISUAL_UPLIFT.md` in full and execute its mandate. Begin by verifying the branch, baseline, working-tree state, required project documents, and local toolchain. Do not edit until the read-only audit and ownership declaration are complete. Follow every authority boundary, acceptance gate, and stop condition in the handoff.

Do not paste credentials, OAuth codes, tokens, or private keys into the session or repository.

---

## 1. Executive mandate

You are the principal art director, technical artist, first-person action-game feel designer, and implementation owner for **one bounded Cobie Nukem Rain City pilot**.

Your objective is to make one critical non-boss Rain City sequence look and feel **dramatically more authored, cohesive, tactile, readable, memorable, and unmistakably Cobie Nukem** while preserving the existing gameplay, production contracts, accessibility behavior, deterministic evidence, Web viability, and original high-resolution retro 2.5D identity.

This is not an invitation to redesign the game or add breadth. It is a focused attempt to discover whether Opus 5 can produce a step-change in visible and tactile quality within the mature system already present.

Use an **ambitious outcome and bounded authority**:

- Begin with a read-only diagnosis.
- Select exactly one dependency-safe Rain City pilot.
- Declare exact file ownership before editing.
- Use read-only parallel critics where useful, but one sequential writer for coupled visual work.
- Implement the smallest coherent set of changes that can materially improve the selected sequence.
- Generate reproducible before/candidate evidence.
- Run the existing mechanical gates.
- Report honestly and stop for human review.

Do not deploy, merge, approve baselines, remove `BETA`, claim human approval, or continue into another mission.

---

## 2. Product context

Cobie Nukem is an original Godot 4.7 shooter with this core promise:

> A fast, funny, 1990s-style FPS starring a leather-jacketed labradoodle, built around ridiculous auto-aim, environmental jokes, secret rooms, and a $25 flight stick.

The presentation is **high-resolution retro 2.5D**:

- authored low-poly 3D spaces;
- original directional illustrated or Blender-rendered enemies;
- original low-poly or illustrated weapon viewmodels;
- modern readability and bounded atmospheric effects;
- no default low-resolution pixelation;
- no protected shooter assets, characters, layouts, dialogue, logos, performances, or trade dress.

Rain City Run is the declared definitive vertical slice. New missions, weapons, enemy families, economy, collectibles, and meta-progression are frozen until Rain City passes its existing gates.

The project is already mechanically substantial. Treat its existing systems as constraints and leverage, not as disposable scaffolding.

---

## 3. Current evidence boundary

At the target baseline:

- WCB-000 through WCB-007 are mechanically closed.
- WCB-008 is active.
- Rain City’s route, encounters, boss seam, materials, presentation foundry, mission audio routing, accessibility contracts, capture tooling, performance gates, native export, and Web export are mechanically evidenced.
- The latest exact capture packet contains five materially distinct non-boss Rain City route views at 1280×720, 1680×1050, 1024×768, and 3440×1440.
- Capture receipts bind dimensions, player/camera pose, active camera ancestry, FOV, and image SHA-256.
- Existing rendered performance checks record average, p50, p95, p99, maximum frame time, stalls, draw calls, object/node counts, memory, and active populations.
- Human approval remains open for district identity, art cohesion, route readability, pacing, feel, humor, mix, motion comfort, photosensitivity, target-Mac play, and physical iPad use.
- WCB-007 boss paths are frozen during WCB-008.
- WCB-009 and later work remain blocked behind the WCB-008 human prerequisite.

Automation may assemble evidence and identify likely improvements. It may not mark subjective terms such as *memorable*, *readable*, *fun*, *cohesive*, or *unmistakable* as passed.

---

## 4. External experiment reviewed before this handoff

The public comparison is [`mshumer/Claude-of-Duty`](https://github.com/mshumer/Claude-of-Duty), inspected at commit `d9b237b75c9304ab8d9ef4cfa0c3568c7c11a853`.

### 4.1 What the public claim actually establishes

The X post said Opus 5 “one-shotted” a custom-code browser FPS with no external assets. The repository adds crucial context:

- The author later corrected “one-shot” to **“zero-shot,”** not a single uninterrupted implementation pass.
- The README says roughly 55,000 lines across 11 subsystems were written by a **fleet of AI agents under orchestration**.
- The short prompt depended on `/loop`, sub-agents, harsh critics, side-by-side review, and “ultracode”; the prompt text alone is not the process.
- The repository’s own honest assessment scores the result **5.05/10** against its modern-military-shooter target; every blind critic chose the real reference frame.
- At 1512×982 and DPR 2, the optimized build reports 28–30 FPS p50, 14–17 FPS p99, and 66–82 ms worst frames.
- Its art passes raised geometry from 5.9M to 11.3M triangles.
- The repository is MIT-licensed, and its build was independently reproduced during preparation of this handoff. Its techniques may be studied, but Cobie must retain original identity and provenance.

Conclusion: the experiment is evidence that Opus 5 can orchestrate an impressive technical prototype. It is **not** evidence that a vague giant prompt automatically produces production-ready art, performance, or taste.

### 4.2 Lessons to carry into Cobie

1. **Write the contract before fan-out.**
   - Shared vocabulary, subsystem ownership, allowed dependencies, deterministic RNG/time, budgets, and evidence commands must be explicit.
   - Cobie already has this in stronger project-specific form. Read it rather than inventing a replacement architecture.

2. **Use parallelism for independent evidence, not coupled visual writes.**
   - The external project found that three rounds of six parallel directory owners improved its visual score by only 0.46 and increased frame-ruining defects in the final round.
   - One sequential owner per coupled visual concern improved the score by 1.00 and reduced defects from 66 to 26.
   - For Cobie, parallel agents may independently critique composition, materials/lighting, feel, performance, and accessibility. They must not concurrently edit overlapping or coupled Rain City presentation paths.

3. **Measure real gameplay distributions, not static averages.**
   - Moving, firing, AI-active profiling exposed stalls hidden by a static-camera median.
   - Cobie already records p50/p95/p99/max and stalls. Preserve that system and profile the actual changed route in motion.
   - Investigate shader/pipeline warm-up only if traces implicate first-use compilation. Do not add speculative pre-warm complexity.

4. **Make visual evidence reproducible.**
   - Fresh isolated state, fixed seeds/frame budgets, temporal reset, exact pose, exact dimensions, and image hashes matter.
   - Cobie already has a stronger Godot-specific receipt system. Do not weaken or bypass it.

5. **Permit evidence to contradict the brief.**
   - The external project’s largest improvement came from rejecting the requested fix after measurements showed the opposite root cause.
   - If the requested treatment conflicts with measured readability, lighting, performance, or Cobie’s identity, state that and follow the evidence.

6. **Visual weight is layered.**
   - Actions should coordinate viewmodel motion, recoil, camera impulse, target reaction, muzzle/impact VFX, transient lighting, decals, and audio transients.
   - Every layer must respect reduced-motion, reduced-flash, density, lifetime, pooling, and voice budgets.

7. **Code-generated everything is not the goal.**
   - The external project explicitly hit a material-richness and character-quality ceiling from procedural-only art.
   - Cobie’s editable Blender and Material Maker sources are an advantage. Preserve them. Do not replace production assets with unmanifested runtime procedural approximations.

### 4.3 Visual ideas worth adapting—not copying

Adapt these general principles to Cobie’s rainy municipal action-comedy language:

- stronger foreground/midground/background separation;
- a dominant route landmark framed at critical entrances;
- material contrast driven by roughness, normal response, edge wear, puddle/decals, and localized grime rather than flat color or universal wet gloss;
- clear key/fill/emissive hierarchy with restrained fog;
- weapon silhouettes that remain readable against both bright and dark backgrounds;
- ADS, muzzle flash, tracers, impacts, hitmarkers, target reactions, and audio behaving as one timed event;
- readable enemy silhouettes and attack language at actual combat distance;
- sparse, legible HUD hierarchy;
- real-motion profiling and hitch attribution after art changes.

Do **not** copy its modern military aesthetic, setting, weapon shapes, UI trade dress, map composition, characters, audio identity, or protected comparisons.

---

## 5. Required reading order

Before editing, read these files in order:

1. `AGENTS.md`
2. `docs/PRD.md` — especially §1.5 and the product/design pillars
3. `docs/IMPLEMENTATION_PLAN.md` — WCB-008 through WCB-011 dependency order
4. `docs/WORLD_CLASS_BUILDOUT_LOG.md` — current state and latest exact commands
5. `docs/VERTICAL_SLICE_SCORECARD.md`
6. `docs/ART_BIBLE.md`
7. `docs/art-briefs/rain_city_run.yaml`
8. `docs/ASSET_MANIFEST.md`
9. `.agents/skills/cobie-godot-production/SKILL.md`
10. `.agents/skills/cobie-visual-foundry/SKILL.md`
11. `.agents/skills/cobie-visual-foundry/references/review-packet.md`
12. `scenes/levels/vancouver/rain_city_gameplay_layout.tscn`
13. `scenes/levels/vancouver/rain_city_presentation.tscn`
14. `scripts/level/rain_city_mission_assembly.gd`
15. `scripts/level/rain_city_material_applier.gd`
16. `tools/blender/build_rain_city_foundry.py`
17. `assets/source/blender/rain_city_run_foundry.blend`
18. relevant Rain City material source graphs under `assets/source/material_maker/`
19. relevant player, weapon, tactile-feedback, VFX, audio, accessibility, performance, and capture code before proposing changes to those systems

Inspect the actual current captures and regenerate them from the durable commands in the buildout log if `/tmp` evidence is no longer present. Never treat a missing ephemeral path as evidence that the packet did not exist.

---

## 6. Hard constraints

### 6.1 Scope

- Work only on one **non-boss Rain City presentation/feel pilot**.
- Default pilot: the Downtown-to-waterfront arrival and its canonical entry composition.
- You may select another non-boss Rain City transition only if the audit demonstrates materially higher impact with equal or lower integration risk.
- Do not touch Salmon Creek or any other mission.
- Do not touch WCB-007 boss-owned paths, Towmaster combat logic, boss state, boss arena progression, or boss acceptance evidence.
- Do not add missions, weapons, enemies, collectible families, economy, meta-progression, or broad editor/tooling features.

### 6.2 Gameplay and architecture

- Preserve collision, navigation, route topology, objective logic, encounter counts, checkpoints, progression, mission timing, and deterministic reset behavior unless an existing authority file explicitly permits a presentation-only seam.
- Presentation geometry must not silently acquire collision or navigation ownership.
- Do not rewrite the player controller, weapon architecture, encounter architecture, or renderer.
- Do not replace Godot with Three.js or introduce a second runtime.
- Do not add a dependency without proving that the existing toolchain cannot meet the requirement and obtaining explicit human approval.

### 6.3 Art direction and provenance

- Preserve high-resolution retro 2.5D and Cobie’s rainy municipal action-comedy identity.
- No direct imitation of Call of Duty, Duke Nukem, or another protected game’s assets, layout, characters, dialogue, logos, weapon silhouettes, UI, performances, or trade dress.
- Real Vancouver is evoked through original silhouettes and fictionalized details, not copied maps, floorplans, storefronts, photography, or branding.
- Runtime production assets require editable or deterministically reproducible source, declared authoring method, hashes, license/provenance, import validation, and asset-manifest updates.
- Image generation may support concepts and turnarounds only. Blender owns deterministic final environment geometry and directional renders where applicable.
- Do not introduce unmanifested one-off images, opaque binary assets without sources, or procedural-only runtime art represented as final production work.

### 6.4 Feel and accessibility

- Preserve responsive fast-retro movement; do not turn Cobie into a realistic military movement simulator.
- Every added recoil, shake, bob, flash, FOV impulse, hit pause, camera displacement, particle density, or screen effect must honor current reduced-motion and reduced-flash contracts.
- Feedback must remain readable at 16:9, 16:10, 4:3 tablet, and ultrawide.
- Audio additions must honor voice, mix, subtitle/caption, and existing mission-routing contracts.
- Do not use automation to claim comfort, humor, mix, fairness, or fun.

### 6.5 Repository safety

- Start from a clean tree on `hermes/world-class-369-buildout`.
- Do not use destructive Git commands.
- Do not overwrite approved baselines.
- Do not merge, push, deploy, publish, or remove `BETA`.
- Keep external reference repositories outside the Cobie repository.
- Never store credentials or OAuth material.

---

## 7. Quality target

The pilot should make the selected sequence visibly better in these specific ways:

### Composition and place identity

- The intended route and dominant landmark read before decorative detail.
- The district remains recognizable in an unlabelled screenshot.
- Foreground, combat plane, route landmark, skyline, and weather depth are clearly separated.
- Architecture avoids repeated flat slabs and generic corridor massing.
- Props, signs, markings, shelter, maintenance clutter, and jokes tell a Rain City-specific story without blocking play.

### Materials and lighting

- Required Rain City material families remain manifested and visibly distinct.
- Wetness is selective: darker albedo and lower roughness where plausible, not universal mirror coating.
- Base tiling remains separate from decals, puddles, route markings, signs, and unique grime.
- Lighting establishes direction before mood.
- Warm shelter/storefront pockets, cool slate/harbour ambience, cyan municipal systems, and warm threat language retain the art-bible hierarchy.
- Fog and bloom support depth without flattening enemies, landmarks, or HUD.
- Web/iPad tiers retain readability without relying on expensive dynamic reflections or excessive transparency.

### Weapon and combat feel

- The active weapon remains an original Cobie silhouette and communicates its role instantly.
- Fire, recoil, viewmodel motion, target response, impact VFX, transient light, decal/surface response, audio transient, and HUD confirmation form one coherent timed event.
- Misses, world impacts, enemy hits, kills, weak points, and destructibles remain meaningfully distinct.
- Feedback is bounded, pooled/capped where required, and accessible.
- No visual polish may hide the reticle, target, route, or damage source.

### Enemy readability

- Threats separate by silhouette and value at intended combat distance.
- Attack telegraphs, hurt/stagger, weak points, shields, and death states remain readable without hue alone.
- Directional billboard scale, fixed feet baseline, world height, orientation, and atlas contracts remain intact.

### Performance and stability

- No unexplained p95/p99/max regression, new hitch pattern, monotonic object/resource growth, duplicated shader/RID diagnostics, capture drift, export failure, or browser console error.
- Any quality/performance tradeoff is explicit by native/Web tier.
- Optimize measured causes only; never trade fidelity or maintainability for speculative micro-optimization.

---

## 8. Execution protocol

### Phase 0 — Verify and freeze the starting point

1. Report branch, HEAD, working-tree status, Godot version, Blender version, Material Maker availability, and export-template state.
2. Confirm whether HEAD equals the target gameplay baseline or differs only by documentation/handoff commits.
3. Run the repository’s current pre-edit documentation, architecture, IP-safety, provenance, import, targeted Rain City, and visual-tool tests as directed by `AGENTS.md` and the latest buildout log.
4. Confirm that current exact Rain City capture evidence is accessible or reproducible.
5. Record any pre-existing failures before changing files.

If the tree is dirty with unrelated work, authority files conflict, the baseline cannot be identified, or the existing candidate cannot be reproduced, stop and report the blocker. Do not guess.

### Phase 1 — Read-only audit

Do not edit files during this phase.

Audit the selected route in the actual game, not only from source or static images. Evaluate:

- first-frame visual hierarchy;
- unlabelled place/district recognition;
- route and landmark readability;
- shape repetition and modular-kit visibility;
- material family separation and texel consistency;
- key/fill/emissive/fog hierarchy;
- environmental storytelling and original humor density;
- enemy silhouette and telegraph readability at combat distance;
- weapon silhouette, firing cadence, recoil, impact response, audio timing, and HUD confirmation;
- reduced-motion/reduced-flash behavior;
- 16:9, 16:10, 4:3, and ultrawide composition;
- moving-combat performance, p50/p95/p99/max, stalls, draw calls, resource/object stability, and Web-specific risk.

Use independent read-only critics if available for:

1. composition and environmental identity;
2. materials, lighting, and atmosphere;
3. weapon/combat feel;
4. enemy/HUD readability and accessibility;
5. performance and production risk.

Require each critic to cite exact scenes, scripts, source assets, captures, or measurements. Reject generic taste statements.

Produce a ranked diagnosis with:

- observed evidence;
- likely root cause;
- smallest coherent intervention;
- visible upside;
- implementation risk;
- verification method;
- whether the idea belongs inside this pilot.

### Phase 2 — Select the pilot and declare ownership

Choose exactly one coherent pilot. Default to the Downtown-to-waterfront arrival unless evidence supports a safer/higher-impact non-boss transition.

Before editing, publish an ownership declaration containing:

- one-sentence acceptance condition;
- exact owned paths;
- frozen paths;
- expected source assets and generated runtime outputs;
- mechanical tests;
- required before/candidate captures and motion clips;
- native/Web performance evidence;
- accessibility checks;
- known risks and rollback boundary.

Expected presentation paths may include the Rain City Blender source/foundry generator, generated GLB, presentation scene, material source graphs/exports, material applier, art brief, manifest, focused contract tests, and packet evidence. Own only the paths actually required.

Do not begin if ownership would overlap frozen boss, route, collision, navigation, or unrelated packet work.

### Phase 3 — Implement sequentially

Use one writer at a time for coupled visual concerns:

1. composition and presentation geometry;
2. materials and lighting;
3. environment dressing and original narrative detail;
4. bounded feel/VFX/audio adjustments, only if the audit proves they are part of the same selected experience;
5. accessibility and quality-tier variants;
6. manifests, tests, and evidence bindings.

After each coherent pass:

- regenerate derived assets from editable source;
- validate import and runtime binding;
- capture the selected view/state;
- inspect the pixels directly;
- run focused tests;
- profile if the pass affects rendering, VFX, audio, or runtime populations;
- revert the pass if it is merely different, introduces drift, or weakens readability.

Do not accumulate several unverified art passes and debug them together.

### Phase 4 — Adversarial review

Run independent read-only critics against:

- the current approved/reference state;
- the candidate at identical staging;
- motion clips from real traversal/combat;
- all supported aspect classes;
- reduced-motion/reduced-flash variants;
- native and packaged-Web performance evidence.

Critics must compare against Cobie’s own art bible and player promise, not protected franchise trade dress.

Require critics to identify:

- the strongest improvement;
- the most visible remaining amateur/placeholder treatment;
- any loss of Cobie identity;
- any readability/accessibility regression;
- any hidden performance or provenance cost;
- whether the candidate should be presented to a human reviewer.

A critic recommendation is not human approval.

### Phase 5 — Full verification and handback

Run focused tests first, then the repository’s root verification flow. Use the exact current commands from `AGENTS.md`, the skills, and the buildout log rather than inventing replacements.

At minimum, the handback must include:

- parser/import result;
- relevant unit and integration results;
- architecture, IP-safety, and provenance results;
- visual-quality tool results;
- exact capture receipts and hashes;
- before/candidate/difference images;
- deterministic motion evidence;
- p50/p95/p99/max/stall/resource evidence for native and applicable Web paths;
- fresh Web and macOS export status if affected;
- source/generated asset map;
- clean `git diff --check`;
- concise residual-risk list;
- explicit list of human questions still open.

Do not approve a new baseline. Stage a candidate packet for human review and stop.

---

## 9. Acceptance conditions

The pilot is mechanically complete only if all of the following are true:

1. Exactly one Rain City non-boss presentation/feel sequence changed.
2. Collision, navigation, progression, encounter count, checkpoints, boss ownership, and deterministic reset remain unchanged.
3. Every production asset has editable/reproducible source, provenance, manifest coverage, deterministic export, and runtime import validation.
4. Before and candidate views share exact pose, seed, quality profile, dimensions, and capture protocol.
5. The candidate has valid 16:9, 16:10, 4:3, and ultrawide evidence with no HUD/safe-area regression.
6. Relevant reduced-motion and reduced-flash states are evidenced.
7. Moving gameplay evidence covers the changed route and any changed combat feedback.
8. Focused and root verification pass, or every blocker is recorded honestly.
9. Native/Web performance and object/resource evidence show no unexplained regression.
10. The candidate packet asks named humans to judge hierarchy, identity, cohesion, readability, feel, humor, mix, motion comfort, photosensitivity, and overall preference.
11. No automation claims those subjective gates passed.
12. No merge, baseline approval, deployment, release promotion, or `BETA` removal occurred.

Success means a mechanically valid candidate that a human can judge. It does not mean the model declares its own work world-class.

---

## 10. Required deliverables

Create or update only the project-authorized equivalents of:

1. **Read-only audit report**
   - ranked findings, evidence, root causes, and selected pilot rationale;
2. **Ownership manifest**
   - acceptance condition, owned/frozen paths, tests, captures, and rollback boundary;
3. **Implementation candidate**
   - focused source and runtime changes;
4. **Visual review packet**
   - before/candidate/difference images and deterministic motion evidence;
5. **Performance and stability report**
   - native/Web distributions, stalls, populations/resources, and known compromises;
6. **Provenance update**
   - source paths, generated paths, hashes, authoring method, tools, and licenses;
7. **Human review form/questions**
   - no pre-filled artistic verdicts;
8. **Final handback**
   - changed files, commands run, real outputs, residual risks, and recommended next decision.

Update `docs/WORLD_CLASS_BUILDOUT_LOG.md` only with factual packet state and evidence. Do not rewrite PRD authority or roadmap order.

---

## 11. Stop conditions

Stop without implementing—or stop at the latest safe phase—if any of these occur:

- branch/baseline ambiguity;
- unrelated dirty work or overlapping ownership;
- required toolchain unavailable and no verified equivalent exists;
- baseline capture/evidence cannot be reproduced;
- the proposed improvement requires collision, navigation, route, progression, boss, or broad architecture changes;
- the candidate depends on unlicensed, unmanifested, non-reproducible, or protected material;
- the visual direction drifts toward generic military realism, direct franchise imitation, or low-resolution pixel-art replacement;
- a quality gain requires unacceptable Web/native performance, accessibility, or maintainability cost;
- targeted tests fail and the root cause cannot be isolated inside owned paths;
- the work would cross into WCB-009, WCB-010, WCB-011, Salmon Creek, or another mission;
- a human-only judgment is required to continue safely.

When blocked, report the exact command, error, evidence path, affected requirement, and smallest safe next decision. Never substitute plausible output for missing evidence.

---

## 12. Final response format

Return a concise but evidence-backed handback using this structure:

```markdown
# Opus 5 Rain City Pilot Handback

## Verdict
- Candidate state:
- Selected pilot:
- Why this pilot:
- Human review required:

## Baseline
- Branch:
- Gameplay baseline:
- Candidate revision/worktree:
- Toolchain:

## Diagnosis
1. Finding — evidence — root cause
2. ...

## Changes
- File/path — purpose

## Verification
- Command — real result
- Capture packet — path/hash/status
- Native performance — p50/p95/p99/max/stalls
- Web performance — p50/p95/p99/max/stalls
- Exports — status

## Before vs candidate
- Strongest improvement:
- Remaining weakness:
- Accessibility/readability risk:
- Performance/provenance cost:

## Human questions still open
- ...

## Recommendation
- Present / revise / reject
- Smallest next action
```

Be skeptical of your own work. Prefer measured truth over compliance with the initial wording. A clean rejection with strong evidence is better than an impressive-looking regression.

---

## Source references

- Matt Shumer X post: <https://x.com/mattshumer_/status/2081054356405731740>
- Claude-of-Duty repository: <https://github.com/mshumer/Claude-of-Duty>
- External prompt: <https://github.com/mshumer/Claude-of-Duty/blob/main/prompt.md>
- External architecture contract: <https://github.com/mshumer/Claude-of-Duty/blob/main/ARCHITECTURE.md>
- External README and honest assessment: <https://github.com/mshumer/Claude-of-Duty/blob/main/README.md>
- Meng To/Vesperfall skills reference: <https://github.com/MengTo/Skills>
- Vesperfall asset-review ledger: <https://vesperfall.mengto.chatgpt.site/asset-catalog>
