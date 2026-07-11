#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
failures=0

echo "Asset/IP scan: prohibited filenames and source phrases"
while IFS= read -r path; do
  case "$path" in
    *[Dd][Uu][Kk][Ee]*|*[Dd][Nn]3[Dd]*|*.[Gg][Rr][Pp]|*.[Mm][Aa][Pp])
      echo "ERROR suspicious runtime path: $path"
      failures=$((failures + 1))
      ;;
  esac
done < <(find assets scenes scripts resources -type f -not -name '*.uid' -not -name '*.import' | sort)

if rg -I -n -i 'duke[ _-]?nukem|hail to the king|come get some|damn, i.m good' assets scenes scripts resources; then
  echo "ERROR protected-source indicator found in runtime content"
  failures=$((failures + 1))
fi

echo "Asset/IP scan: manifest coverage"
while IFS= read -r asset; do
  if ! rg -F -q "\`$asset\`" docs/ASSET_MANIFEST.md; then
    echo "ERROR asset missing manifest entry: $asset"
    failures=$((failures + 1))
  fi
done < <(find assets -type f -not -name '*.import' -not -name '.gitkeep' | sort)

if (( failures > 0 )); then
  echo "Asset/IP scan failed with $failures issue(s)."
  exit 1
fi
echo "Asset/IP scan passed. This is a heuristic, not legal clearance."
