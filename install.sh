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
    sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
  *)        PARENT="$1" ;;
esac

# Running from a clone? Copy locally. Otherwise fetch the tarball.
#
# Two guards, because the README documents a `curl ... | sh` one-liner. Piped in,
# $0 is "sh" and $SELF_DIR resolves to the *caller's* working directory — so a
# bare `skills/` there (common for the people this plugin is for) would make the
# script install their own skills instead of downloading this repo. Require $0 to
# be a real file, and require a marker only this repo has. The marker is the
# plugin manifest rather than any one package: no package name is hardcoded
# anywhere in this script, so renaming one cannot silently send it downloading.
if [ -f "$0" ]; then
  SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
else
  SELF_DIR=""
fi
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/.claude-plugin/plugin.json" ] && [ -d "$SELF_DIR/skills" ]; then
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
# The trailing `true` matters: under `set -eu` the loop's exit code is the last
# test's, so a final directory without a SKILL.md would kill the script silently.
NAMES=$(cd "$SRC" || exit 1; for d in */; do [ -f "$d/SKILL.md" ] && basename "$d"; done; true)
[ -n "$NAMES" ] || { echo "No skill packages found under $SRC" >&2; exit 1; }
COUNT=$(echo "$NAMES" | grep -c . || true)

# The replace branch below runs `rm -rf "$PARENT/$n"` and then copies from
# "$SRC/$n". If those are the same directory, the copy source is deleted first.
SRC_ABS=$(CDPATH= cd -- "$SRC" && pwd)
DEST_ABS=$(mkdir -p "$PARENT" && CDPATH= cd -- "$PARENT" && pwd)
if [ "$SRC_ABS" = "$DEST_ABS" ]; then
  echo "Source and destination are the same directory ($DEST_ABS). Nothing to do." >&2
  exit 1
fi

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
