"""Compose the deterministic Blender frame set into the runtime 8x4 atlas."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "builds/generated/rain_city_umbrella_enforcer"
OUTPUT = ROOT / "assets/sprites/enemies/atlases/umbrella_shield_enforcer_atlas.png"
FRAME_SIZE = 256


def main() -> None:
    atlas = Image.new("RGBA", (FRAME_SIZE * 8, FRAME_SIZE * 4), (0, 0, 0, 0))
    for row in range(4):
        for column in range(8):
            path = FRAMES / f"frame_{row}_{column}.png"
            if not path.is_file():
                raise FileNotFoundError(path)
            frame = Image.open(path).convert("RGBA")
            if frame.size != (FRAME_SIZE, FRAME_SIZE):
                raise ValueError(f"Unexpected frame dimensions: {path}: {frame.size}")
            atlas.alpha_composite(frame, (column * FRAME_SIZE, row * FRAME_SIZE))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT, optimize=True)
    print(f"Composed {OUTPUT} ({atlas.width}x{atlas.height})")


if __name__ == "__main__":
    main()
