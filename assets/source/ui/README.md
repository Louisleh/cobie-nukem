# Cobie HUD portrait source

`cobie_portrait_set_a.png` is the owner-selected three-panel concept generated
from the project cover on 2026-07-17. Only its healthy and critical panels are
used in-game. `cobie_portrait_healthy_clean.png` is a precise follow-up edit
that removes a crack-like reflection from the healthy aviators.

Runtime assets are square 512×512 crops under `assets/ui/portraits/`:

- `cobie_healthy.png`: health at or above 65%.
- `cobie_critical.png`: health below 65%.

The unused middle concept is retained only inside the source sheet for
provenance and is not imported or referenced at runtime.
