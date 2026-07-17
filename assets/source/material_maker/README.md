# Cobie Material Maker library

This folder stores editable Material Maker graphs. Generated texture maps belong
under `assets/textures/materials/`; the `.ptex` graph is the source of truth.

The first pilot graph, `salmon_wet_municipal.ptex`, establishes the authored
wet-surface language for Salmon Creek. Rain City's production family adds
`rain_city_wet_asphalt.ptex`, `rain_city_seawall_concrete.ptex`, and
`rain_city_harbour_steel.ptex`. All use original graph parameters and no
third-party textures. Future siblings remain painted concrete, laboratory
panels, sports field, tunnel wall, rain-darkened wood, and glass-tower panels.

Export locally with Material Maker 1.7 at 512 or 1024 pixels for Web assets. Keep
roughness and normal detail restrained so critical actors remain readable.
