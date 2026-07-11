#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.4.0-mobile-rc1}"
REVISION="${GITHUB_SHA:-$(git rev-parse --verify HEAD 2>/dev/null || printf unknown)}"
SHORT_REVISION="${REVISION:0:12}"
PACKAGES_DIR="builds/packages"
PAGES_DIR="builds/pages"

if [[ "${SKIP_VALIDATION:-0}" != "1" ]]; then
  QA_EXPORTS=1 bash tools/release_validate.sh
fi

required=(
  builds/web/index.html
  builds/web/index.js
  builds/web/index.pck
  builds/web/index.wasm
  builds/macos/CobieNukem.zip
  web/landing/index.html
  web/landing/styles.css
  assets/brand/cobie_nukem_cover.png
)
for path in "${required[@]}"; do
  [[ -s "$path" ]] || { echo "ERROR required package input missing/empty: $path"; exit 1; }
done

rm -rf "$PACKAGES_DIR" "$PAGES_DIR"
mkdir -p "$PACKAGES_DIR" "$PAGES_DIR/play" "$PAGES_DIR/assets"

cp -R builds/web/. "$PAGES_DIR/play/"
cp web/landing/styles.css "$PAGES_DIR/styles.css"
cp assets/brand/cobie_nukem_cover.png "$PAGES_DIR/assets/cobie-nukem-cover.png"
sed -e "s/__BUILD_VERSION__/$VERSION/g" \
    -e "s/__GIT_REVISION__/$SHORT_REVISION/g" \
    web/landing/index.html > "$PAGES_DIR/index.html"
touch "$PAGES_DIR/.nojekyll"

python3 - "$VERSION" <<'PY'
from pathlib import Path
import sys
import zipfile

version = sys.argv[1]
source = Path("builds/web")
target = Path("builds/packages") / f"cobie-nukem-{version}-itch.zip"
with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for path in sorted(source.rglob("*")):
        if path.is_file() and not path.name.endswith(".import"):
            archive.write(path, path.relative_to(source).as_posix())
PY

cp builds/macos/CobieNukem.zip "$PACKAGES_DIR/cobie-nukem-$VERSION-macos-unsigned.zip"

python3 - "$PACKAGES_DIR/cobie-nukem-$VERSION-itch.zip" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    names = set(archive.namelist())
    required = {"index.html", "index.js", "index.pck", "index.wasm"}
    missing = sorted(required - names)
    if missing:
        raise SystemExit(f"ERROR itch.io archive missing root entries: {', '.join(missing)}")
    if any(name.startswith("builds/") for name in names):
        raise SystemExit("ERROR itch.io archive contains an extra builds/ directory")
PY

(
  cd "$PACKAGES_DIR"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum ./*.zip > SHA256SUMS.txt
  else
    shasum -a 256 ./*.zip > SHA256SUMS.txt
  fi
)

cat > "$PACKAGES_DIR/BUILD_INFO.txt" <<EOF
Cobie Nukem release package
Version: $VERSION
Git revision: $REVISION
Generated UTC: $(date -u +%FT%TZ)
Web entry: builds/web/index.html
Pages entry: builds/pages/index.html
itch.io archive: cobie-nukem-$VERSION-itch.zip
macOS archive: cobie-nukem-$VERSION-macos-unsigned.zip
EOF

echo "Packaged release $VERSION ($SHORT_REVISION)"
echo "  Pages: $PAGES_DIR/index.html"
echo "  itch.io: $PACKAGES_DIR/cobie-nukem-$VERSION-itch.zip"
echo "  macOS: $PACKAGES_DIR/cobie-nukem-$VERSION-macos-unsigned.zip"
cat "$PACKAGES_DIR/SHA256SUMS.txt"
