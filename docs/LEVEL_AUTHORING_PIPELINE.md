# Level-authoring pipeline decision

FuncGodot commit `d68960dfce8b99f0dbc571abfc3fd9c396126b76` and example commit `d9a02b846d1de0fcca338604d8631da282112ba7` were piloted with TrenchBroom 2026.1 under Godot 4.7. A 10,128-byte map produced a 17,201-byte, 29-node scene with 14 mesh/collision nodes and no engine errors.

Decision: **viable isolated pilot, not adopted as Salmon Creek source of truth**. The measured path is promising for a disposable Vancouver graybox, but production adoption still requires:

- Cobie FGD entities for encounters, enemies, pickups, objectives, doors, secrets, checkpoints, audio, and surface metadata;
- deterministic reimport and readable diffs;
- navigation bake/reachability validation;
- Compatibility/Web export and performance proof;
- a strict ownership rule preventing hand-edited generated scenes.

Salmon Creek remains Godot-native. Vancouver may use a short-lived brush blockout experiment after the current vertical-slice human gates; typed mission Resources remain authoritative regardless of geometry tool.
