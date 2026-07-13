# Level-authoring pipeline decision

FuncGodot commit `d68960dfce8b99f0dbc571abfc3fd9c396126b76` and example commit `d9a02b846d1de0fcca338604d8631da282112ba7` were piloted with TrenchBroom 2026.1 under Godot 4.7. The first editor-generated artifact was 17,201 bytes with 29 nodes. A stricter scripted rebuild expanded the measurement to the complete generated tree: 52 nodes, eight mesh instances, 11 collision shapes, 16 leaf point entities, and a 669,812-byte packed scene in 238–289 ms. A collision-derived navigation bake produced eight vertices and four polygons. Two consecutive rebuilds differed only in Godot-generated `unique_id` values; content, resources, transforms, and node order were stable.

A Compatibility-renderer Web export also succeeded: 1.1 MB PCK plus the standard 38 MB Godot WASM, PCK SHA-256 `a50c8db6b83e8b81f7b68576776be4a9ffd5c9c630aa5b769f40634ce6f536d1`. However, the all-resources pilot bundled FuncGodot editor/runtime scripts into the PCK. That is unacceptable for Cobie's production export and confirms that any future adoption needs a generated-geometry-only ownership/export rule.

Decision: **viable isolated pilot, not adopted as Salmon Creek source of truth**. The measured path is promising for a disposable Vancouver graybox, but production adoption still requires:

- Cobie FGD entities for encounters, enemies, pickups, objectives, doors, secrets, checkpoints, audio, and surface metadata;
- stable-ID normalization so generated `unique_id` churn cannot pollute review diffs;
- representative multi-zone navigation reachability rather than the pilot's four-polygon collision bake;
- an export filter/build step that excludes FuncGodot and source `.map` tooling from the PCK;
- Compatibility/Web render and performance proof inside a Cobie-sized encounter stress scene;
- a strict ownership rule preventing hand-edited generated scenes.

Salmon Creek remains Godot-native. Vancouver may use a short-lived brush blockout experiment after the current vertical-slice human gates; typed mission Resources remain authoritative regardless of geometry tool. The pilot is now sufficient to reject premature production adoption, not sufficient to claim a Cobie level-authoring pipeline.
