# Cobie Material Maker library

This folder stores editable Material Maker graphs. Generated texture maps belong
under `assets/textures/materials/`; the `.ptex` graph is the source of truth.

The first pilot graph, `salmon_wet_municipal.ptex`, establishes the authored
wet-surface language for Salmon Creek. Rain City now owns ten manifested
families spanning wet streets, buildings, seawall, harbour, terminal, Slice,
wood, and route decals. Mount Hood owns ten snow, rock, road, lodge, lift,
glass, and warm-window families. Dark Side of Fetch owns twelve regolith,
habitat, lunar-metal, glass, landmark, and safety families. Pier Pressure owns
thirteen coastal concrete, sand, pier, marina, ocean, palm, and warm-light
families. All use original graph parameters and no third-party textures.

`tools/materials/build_mission_material_library.py` deterministically rebuilds
the current 512px albedo, tangent-space normal, packed ORM, Material Maker
source graphs, and Godot material Resources. Material Maker remains the visual
authoring environment; the script keeps CI and local reproduction independent
of GUI automation.

Export locally with Material Maker 1.7 at 512 or 1024 pixels for Web assets. Keep
roughness and normal detail restrained so critical actors remain readable.
