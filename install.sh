#!/bin/sh
# Install the ui-contract skills into whichever agent you use.
#
#   ./install.sh                 -> ~/.claude/skills           (Claude Code, all projects)
#   ./install.sh project         -> ./.claude/skills           (this repo only)
#   ./install.sh windsurf        -> ./.windsurf/skills
#   ./install.sh cline           -> ./.cline/skills
#   ./install.sh ~/some/dir      -> that directory
#
# Any agent that reads the SKILL.md format works; if yours keeps skills
# somewhere else, pass that path directly.
#
# If you use Claude Code's plugin mechanism, you don't need this script —
# install the plugin from the marketplace instead. This exists for agents
# that only understand a skills directory.
#
# Every directory under skills/ that contains a SKILL.md is installed. The
# skill set is composable: the ui-contract-* units call each other and call
# the domain-agnostic primitives, so installing a subset breaks the chain.

set -eu

REPO="${UI_CONTRACT_REPO:-yannikzz/ui-contract}"
REF="${UI_CONTRACT_REF:-main}"

case "${1:-claude}" in
  claude)   PARENT="$HOME/.claude/skills" ;;
  project)  PARENT="./.claude/skills" ;;
  windsurf) PARENT="./.windsurf/skills" ;;
  cline)    PARENT="./.cline/skills" ;;
  -h|--help)
    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
  *)        PARENT="$1" ;;
esac

# Running from a clone? Copy locally. Otherwise fetch the tarball.
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -d "$SELF_DIR/skills" ]; then
  SRC="$SELF_DIR/skills"
  CLEANUP=""
else
  command -v curl >/dev/null 2>&1 || { echo "install.sh needs curl (or run it from a clone)." >&2; exit 1; }
  command -v tar  >/dev/null 2>&1 || { echo "install.sh needs tar." >&2; exit 1; }
  TMP=$(mktemp -d)
  CLEANUP="$TMP"
  echo "Fetching $REPO@$REF ..."
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" \
    | tar -xz -C "$TMP" --strip-components=1
  SRC="$TMP/skills"
  [ -d "$SRC" ] || { echo "Downloaded archive has no skills/ directory" >&2; exit 1; }
fi

# The package list has exactly one source: the disk. Nothing here is hardcoded.
NAMES=$(cd "$SRC" && for d in */; do [ -f "$d/SKILL.md" ] && basename "$d"; done)
COUNT=$(echo "$NAMES" | grep -c .)

EXISTING=""
for n in $NAMES; do [ -e "$PARENT/$n" ] && EXISTING="$EXISTING $n"; done
if [ -n "$EXISTING" ]; then
  printf 'Replace these existing skills in %s ?%s [y/N] ' "$PARENT" "$EXISTING"
  read -r reply </dev/tty || reply=n
  case "$reply" in
    y|Y) for n in $EXISTING; do rm -rf "$PARENT/$n"; done ;;
    *)   echo "Left them alone."; [ -n "$CLEANUP" ] && rm -rf "$CLEANUP"; exit 0 ;;
  esac
fi

mkdir -p "$PARENT"
# -R copies everything a package holds at runtime, including non-markdown
# assets (code templates, the health-check script). Development assets —
# tests, evals, examples — deliberately live outside skills/ and are not
# shipped to users.
for n in $NAMES; do cp -R "$SRC/$n" "$PARENT/$n"; done
[ -n "$CLEANUP" ] && rm -rf "$CLEANUP"

echo "Installed $COUNT skills to $PARENT"
echo "Start a new agent session, then ask for a layout spec / 界面规范 to trigger it."
