# Audit Package Manifest

The generated source archive is produced from committed Git files, so it excludes `.godot/`, `builds/`, local saves, caches, and other ignored artifacts.

Included:

- Godot project configuration, export presets, scenes, scripts, Resources, tests, and tools.
- Original project assets required to load and inspect the game.
- Product, architecture, QA, release, phase-roadmap, and content-authoring documentation.
- This audit prompt and handoff guide.

Not included:

- Generated Web/macOS exports and historical release ZIPs.
- `.godot` import/editor cache.
- `user://` settings or saves.
- Git object history; the archive records its source revision in its filename.
- Auditor output, which should be written into the live repository handoff output folder or returned separately.
