#!/bin/sh
# Development counterpart to install.sh: symlink the packages instead of copying
# them, so an edit in this clone is live in the agent's skill directory with no
# sync step. install.sh is what users run; this is what the author runs.
#
#   ./dev-link.sh                -> ~/.claude/skills           (all projects)
#   ./dev-link.sh project        -> ./.claude/skills
#   ./dev-link.sh ~/some/dir     -> that directory
#   ./dev-link.sh --unlink       -> remove this repo's links from ~/.claude/skills
#
# A skill directory is read fresh at every session start, so the link makes the
# content live; only *adding or renaming* a package needs this script re-run.
# It is idempotent — run it as often as you like.
#
# Trade-off worth knowing before you run it: every package is now global and
# unversioned. A half-finished SKILL.md, a checked-out branch, a git stash — each
# of those changes what every other project's agent loads, immediately.

set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$SELF_DIR/skills"
[ -f "$SELF_DIR/.claude-plugin/plugin.json" ] && [ -d "$SRC" ] || {
  echo "dev-link.sh must be run from a clone of the ui-contract repo." >&2; exit 1; }

UNLINK=no
case "${1:-claude}" in
  claude)   PARENT="$HOME/.claude/skills" ;;
  project)  PARENT="./.claude/skills" ;;
  --unlink) PARENT="$HOME/.claude/skills"; UNLINK=yes ;;
  -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *)        PARENT="$1" ;;
esac
mkdir -p "$PARENT"
DEST=$(CDPATH= cd -- "$PARENT" && pwd)

# Same rule as install.sh: the package list comes from the disk, never a hardcoded
# list. Renaming a directory here is the only edit a rename needs.
NAMES=$(cd "$SRC" && for d in */; do [ -f "$d/SKILL.md" ] && basename "$d"; done; true)
[ -n "$NAMES" ] || { echo "No skill packages found under $SRC" >&2; exit 1; }

# Sweep first: a link pointing into this repo whose target is gone is the residue
# of a rename or a deletion. Nothing else in the directory is touched — other
# skills, and real directories, are left exactly as they are.
SWEPT=0
for p in "$DEST"/*; do
  [ -L "$p" ] || continue
  t=$(readlink "$p")
  case "$t" in "$SRC"/*) [ -e "$t" ] || { rm -f "$p"; SWEPT=$((SWEPT+1)); } ;; esac
done

if [ "$UNLINK" = yes ]; then
  N=0
  for p in "$DEST"/*; do
    [ -L "$p" ] || continue
    case "$(readlink "$p")" in "$SRC"/*) rm -f "$p"; N=$((N+1)) ;; esac
  done
  echo "Removed $N links from $DEST. Run ./install.sh for a copied install."
  exit 0
fi

# A real directory in the way is someone's installed copy — possibly a released
# version of this very plugin. Back it up rather than deleting it, and say where.
BACKUP="$DEST/.dev-link-backup"
MOVED=""
for n in $NAMES; do
  p="$DEST/$n"
  if [ -e "$p" ] && [ ! -L "$p" ]; then
    mkdir -p "$BACKUP"
    rm -rf "$BACKUP/$n"
    mv "$p" "$BACKUP/$n"
    MOVED="$MOVED $n"
  fi
  ln -sfn "$SRC/$n" "$p"
done

COUNT=$(echo "$NAMES" | grep -c . || true)
echo "Linked $COUNT packages into $DEST"
[ "$SWEPT" -gt 0 ] && echo "Swept $SWEPT stale link(s) from a rename or deletion."
[ -n "$MOVED" ] && echo "Moved aside (copies, now shadowed):$MOVED -> $BACKUP"
echo "Edits are live from the next session on; re-run only after adding or renaming a package."
