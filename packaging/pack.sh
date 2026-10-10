#!/bin/sh
# Build dist/ui-contract-<version>.zip — the plugin as a user installs it, and nothing
# of how it was made. For sharing with someone who cannot reach this repo.
#
#   ./packaging/pack.sh
#
# What goes in is a closed list, not "everything minus the dev files": the manifests,
# skills/, install.sh, and packaging/readme-for-package.md as the README. A new
# top-level directory therefore stays out until it is added here on purpose — the
# safe direction for a file that leaves the repo.
#
# Built from HEAD with `git archive`, not from the working tree, so what ships is
# exactly what is committed: no .DS_Store, no half-finished edit. That is also why it
# refuses to run with uncommitted changes to anything it ships — the zip would
# silently differ from the files on screen.
#
# Bump the version in both manifests before packing a release someone already has:
# Claude Code decides whether an update exists by comparing it.

set -eu
cd "$(dirname "$0")/.."

SHIPPED=".claude-plugin skills install.sh packaging/readme-for-package.md"

for tool in git python3 zip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "pack.sh needs $tool." >&2; exit 1; }
done

if [ -n "$(git status --porcelain -- $SHIPPED)" ]; then
  echo "Uncommitted changes in what the zip ships:" >&2
  git status --short -- $SHIPPED >&2
  echo "The zip is built from HEAD. Commit first, or it will not contain these." >&2
  exit 1
fi

VERSION=$(python3 -I - <<'PY'
import json, sys
p = json.load(open('.claude-plugin/plugin.json'))['version']
m = [x['version'] for x in json.load(open('.claude-plugin/marketplace.json'))['plugins'] if x['name'] == 'ui-contract']
if m != [p]:
    sys.exit(f'version disagrees: plugin.json {p}, marketplace.json {m}')
print(p)
PY
)

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
STAGE="$TMP/ui-contract"
mkdir -p "$STAGE"

# shellcheck disable=SC2086 # word-splitting the closed list is the point
git archive HEAD $SHIPPED | tar -x -C "$STAGE"
mv "$STAGE/packaging/readme-for-package.md" "$STAGE/README.md"
rmdir "$STAGE/packaging"
sed "s/{{VERSION}}/$VERSION/g" "$STAGE/README.md" > "$TMP/readme" && mv "$TMP/readme" "$STAGE/README.md"

# The eval suite lives in testing/, which does not ship. A manifest pointing at a
# directory that is not there is a dangling reference in the one file every
# consumer reads first.
python3 -I - "$STAGE/.claude-plugin/plugin.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m.pop('experimental', None)
open(p, 'w').write(json.dumps(m, indent=2, ensure_ascii=False) + '\n')
PY

if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$STAGE" >/dev/null || { echo "claude plugin validate rejected the staged package:" >&2; claude plugin validate "$STAGE" >&2; exit 1; }
fi

mkdir -p dist
OUT="$PWD/dist/ui-contract-$VERSION.zip"
rm -f "$OUT"
(cd "$TMP" && zip -qrX "$OUT" ui-contract)

echo "Built $OUT"
echo "  $(find "$STAGE" -type f | wc -l | tr -d ' ') files, $(du -h "$OUT" | cut -f1 | tr -d ' ') — version $VERSION, from $(git rev-parse --short HEAD)"
