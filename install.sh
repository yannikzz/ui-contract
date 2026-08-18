#!/bin/sh
# Install the ui-contract skill into whichever agent you use.
#
#   ./install.sh                 -> ~/.claude/skills           (Claude Code, all projects)
#   ./install.sh project         -> ./.claude/skills           (this repo only)
#   ./install.sh windsurf        -> ./.windsurf/skills
#   ./install.sh cline           -> ./.cline/skills
#   ./install.sh ~/some/dir      -> that directory
#
# Any agent that reads the SKILL.md format works; if yours keeps skills
# somewhere else, pass that path directly.

set -eu

REPO="${UI_CONTRACT_REPO:-yannikzz/ui-contract}"
REF="${UI_CONTRACT_REF:-main}"
NAME="ui-contract"

case "${1:-claude}" in
  claude)   PARENT="$HOME/.claude/skills" ;;
  project)  PARENT="./.claude/skills" ;;
  windsurf) PARENT="./.windsurf/skills" ;;
  cline)    PARENT="./.cline/skills" ;;
  -h|--help)
    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
  *)        PARENT="$1" ;;
esac

DEST="$PARENT/$NAME"

# Running from a clone? Copy locally. Otherwise fetch the tarball.
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -f "$SELF_DIR/skills/$NAME/SKILL.md" ]; then
  SRC="$SELF_DIR/skills/$NAME"
  CLEANUP=""
else
  command -v curl >/dev/null 2>&1 || { echo "install.sh needs curl (or run it from a clone)." >&2; exit 1; }
  command -v tar  >/dev/null 2>&1 || { echo "install.sh needs tar." >&2; exit 1; }
  TMP=$(mktemp -d)
  CLEANUP="$TMP"
  echo "Fetching $REPO@$REF ..."
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" \
    | tar -xz -C "$TMP" --strip-components=1
  SRC="$TMP/skills/$NAME"
  [ -f "$SRC/SKILL.md" ] || { echo "Downloaded archive has no skills/$NAME/SKILL.md" >&2; exit 1; }
fi

if [ -e "$DEST" ]; then
  printf 'Replace existing %s ? [y/N] ' "$DEST"
  read -r reply </dev/tty || reply=n
  case "$reply" in
    y|Y) rm -rf "$DEST" ;;
    *)   echo "Left it alone."; [ -n "$CLEANUP" ] && rm -rf "$CLEANUP"; exit 0 ;;
  esac
fi

mkdir -p "$PARENT"
cp -R "$SRC" "$DEST"
[ -n "$CLEANUP" ] && rm -rf "$CLEANUP"

echo "Installed to $DEST"
echo "Start a new agent session, then ask for a layout spec / 界面规范 to trigger it."
