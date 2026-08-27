#!/bin/sh
# Wireframe colour discipline. Reports violations; fixes nothing.
#
# Exit 0 = clean. Exit 1 = violations. Exit 2 = no wireframe here, nothing to check.
#
# THIS IS NOT A CI GATE, and do not describe it as one. The wireframe lives in the
# workbench, which is not committed, so on most projects this script never runs in CI
# at all. Its reader is the agent that is editing the wireframe right now — which is
# also the only moment the rule can still be applied cheaply.
#
# TODO adjust the three paths below to this project.
set -u
WIRE_SRC=".ui-contract-local/wireframe/src"
APPARATUS="$WIRE_SRC/inspect.tsx"             # the ONE file allowed to hold colour values
PARTS="$WIRE_SRC/wire.tsx"                    # NEUTRAL lives here, and nowhere else

# The declared list is READ out of the apparatus file's own header, not carried here.
# One decision, one home: adding a name shows up in the diff of the file the name is
# being added to. See that file's `APPARATUS:` line.

FAIL=0
ok(){    printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad(){   printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }
skip(){  printf '  \033[33m—\033[0m %s\n' "$1"; }

if [ ! -d "$WIRE_SRC" ]; then
  echo "No wireframe at $WIRE_SRC — nothing to check."
  echo "It is not committed by design; regenerate it with ui-contract-wireframe."
  exit 2
fi

# ── COLOUR KNOWLEDGE · keep these two values byte-identical with ────────────
#   testing/structure/invariants.sh
#   skills/ui-contract-wireframe/assets/check-colours.sh.template
#   skills/ui-contract-audit/assets/audit.sh.template
#
# invariants.sh check 33 compares the three. It does NOT generate them: this repo's
# existing shape for one-fact-in-three-places is comparison (check 17 does it for eval
# graders), and comparison needs no new concept, no build step, and no answer to
# "where does generation run for a template that ships into someone else's repo".
#
# They had drifted three ways before the check existed, each missing what the others
# had: audit.sh matched only 6-digit hex and no Tailwind scale at all, so `#fff` and
# `bg-blue-500` in feature code were green; the other two missed lab()/lch()/color().
# The value below is the union.
#
# ⚠ The named list is TRIMMED, on purpose. CSS has 148 named colours and carrying all
# of them in three files is maintenance noise for words that never appear in real code.
# **What gets through: the rare ones** — `papayawhip`, `mediumaquamarine` and friends.
# A name list is never complete; what makes it honest is saying so here.
#
# ⚠ OUT OF SCOPE: `toHex` in theme-studio.html.template and inspect.tsx.template. That
# is a colour *parser*, not a colour *detector* — different knowledge — and the two
# copies are in two languages in two packages, which implementation.md already records
# as unshareable. Do not read this check as "colour knowledge is now covered".
COLOUR_NOTATION='#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(|\boklch\(|\boklab\(|\blab\(|\blch\(|\bcolor\(|\b(bg|text|border|ring|fill|stroke|outline|divide|from|via|to)-(red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|slate|gray|grey|zinc|neutral|stone)-[0-9]{2,3}\b'
COLOUR_NAMED='aqua|beige|black|blue|brown|chartreuse|chocolate|coral|crimson|cyan|darkblue|darkgreen|darkred|deeppink|dodgerblue|firebrick|forestgreen|fuchsia|gold|goldenrod|gray|green|grey|hotpink|indigo|ivory|khaki|lavender|lime|magenta|maroon|navy|olive|orange|orangered|orchid|pink|plum|purple|rebeccapurple|red|salmon|seagreen|sienna|silver|skyblue|steelblue|tan|teal|tomato|turquoise|violet|wheat|white|yellow'

# Two more things this file cannot catch, both deliberate, both stated so a green run is
# not read as "no colour leaked in":
#   1. A brand colour added INTO the NEUTRAL map. Values are legal there — they are the
#      wireframe's own greys — so "is what you added actually grey" stays a review question.
#   2. Anything inside the apparatus file. That is what the exemption means.
#
# A named colour cannot be caught by word shape alone (`whitespace` contains `white`), so
# it is matched on context: the word has to sit in the value position of a colour-ish
# property. That misses named colours written into a Tailwind class or a template literal.
NOTATION="$COLOUR_NOTATION"
NAMED='([A-Za-z]*[Cc]olor|background|fill|stroke|outline|boxShadow|textShadow)[[:space:]]*:[[:space:]]*.?('"$COLOUR_NAMED"')\b'

echo "1. Colour values live only in NEUTRAL and in the apparatus file"
if [ ! -f "$APPARATUS" ]; then
  # Not a pass and not a silent skip. Either the apparatus was never split out, or
  # the path above is wrong — and those need different fixes, so say both.
  bad "no apparatus file at $APPARATUS — either it was never split out of wire.tsx, or APPARATUS above points at the wrong path. Until it exists there is no declared exemption, so every colour value below is unexplained"
else
  # Everything except the apparatus file. The NEUTRAL block is excised from $PARTS by
  # line range rather than by pattern: the map is the declared home for values, and a
  # pattern that tried to skip "lines that look like the map" would also skip a line
  # somebody wrote to look like it.
  HITS=""
  for f in $(find "$WIRE_SRC" -type f \( -name '*.tsx' -o -name '*.ts' -o -name '*.css' \) 2>/dev/null); do
    [ "$f" = "$APPARATUS" ] && continue
    if [ "$f" = "$PARTS" ]; then
      BODY=$(awk '/^export const NEUTRAL/{skip=1} skip&&/^}/{skip=0;next} !skip' "$f")
    else
      BODY=$(cat "$f")
    fi
    H=$(printf '%s\n' "$BODY" | grep -nE "$NOTATION" | sed "s|^|$f:|")
    N=$(printf '%s\n' "$BODY" | grep -nE "$NAMED"    | sed "s|^|$f:|")
    [ -n "$H" ] && HITS="$HITS$H
"
    [ -n "$N" ] && HITS="$HITS$N
"
  done
  HITS=$(printf '%s' "$HITS" | grep -v '^$')
  if [ -n "$HITS" ]; then
    bad "colour values outside NEUTRAL and outside $APPARATUS:"
    printf '%s\n' "$HITS" | sed 's/^/      /'
    printf '      → route these through var(--wire-*); add the role to NEUTRAL if it is missing, and what you add must be grey\n'
  else
    ok "no colour values outside NEUTRAL and $APPARATUS"
  fi
fi

echo "2. The apparatus file exports only what is declared"
if [ ! -f "$APPARATUS" ]; then
  skip "no apparatus file — check 1 already reported it"
else
  # Absence is not "nothing declared" — it means the declaration was lost or translated,
  # and continuing would silently exempt every export in the file.
  DECLARED=$(sed -n 's/.*APPARATUS:[[:space:]]*//p' "$APPARATUS" | head -1)
  if [ -z "$DECLARED" ]; then
    bad "no APPARATUS: line in $APPARATUS — the closed list is declared there and read from there. If the header was translated, the marker itself must stay ASCII"
    DECLARED="__none__"
  fi
  EXTRA=""
  for n in $(grep -oE '^export (const|function|type) [A-Za-z_][A-Za-z0-9_]*' "$APPARATUS" | awk '{print $3}'); do
    case " $DECLARED " in
      *" $n "*) ;;
      *) EXTRA="$EXTRA $n" ;;
    esac
  done
  if [ -n "$EXTRA" ]; then
    bad "undeclared exports in $APPARATUS:$EXTRA"
    printf '      → a product component moved in here may hardcode colour, which is why the list is closed.\n'
    printf '        If it really is apparatus, add the name to the APPARATUS: line in that file — that edit shows up in the diff, beside the thing being added.\n'
  else
    ok "apparatus exports match the declared list"
  fi
fi

echo "3. Every NEUTRAL role has a decision recorded in SKIN"
# The gap this closes was found in a real wireframe: NEUTRAL had grown to six border
# roles while the visual spec declared two, and three of the six were in SKIN nowhere
# at all. With the preview on they stayed wireframe grey — **a half-broken theme**,
# which reads as a rendering bug rather than as a missing decision.
#
# Nothing else notices this. Check 1 only looks at where values live; the health check
# only compares the declaration table against the token file. A wireframe that quietly
# grows a role is inventing spec, and the only trace is a role nobody mapped.
#
# An EMPTY mapping is a valid answer — it says "this role deliberately stays neutral".
# What is not valid is absence: that is nobody having decided.
if [ ! -f "$PARTS" ]; then
  skip "no $PARTS"
else
  ROLES=$(awk '/^export const NEUTRAL/{f=1;next} f&&/^}/{exit} f' "$PARTS" | grep -oE "'--wire-[a-z-]+'" | tr -d "'" | sort -u)
  MAPPED=$(awk '/^export const SKIN/{f=1;next} f&&/^}/{exit} f' "$PARTS" | grep -oE "'--wire-[a-z-]+'" | tr -d "'" | sort -u)
  UNDECIDED=""
  for r in $ROLES; do printf '%s\n' "$MAPPED" | grep -qx -- "$r" || UNDECIDED="$UNDECIDED $r"; done
  if [ -n "$UNDECIDED" ]; then
    bad "roles in NEUTRAL with no line in SKIN:$UNDECIDED"
    printf '      → each one needs a token name, or an empty string meaning "stays neutral on purpose".\n'
    printf '        Absence is not a decision, and with the preview on it renders as a half-skinned theme.\n'
  else
    ok "every NEUTRAL role has a SKIN decision"
  fi
fi

printf '\n'
[ $FAIL -eq 0 ] && printf '\033[32mClean.\033[0m Remember: this is not a CI gate — see the header.\n' \
                || printf '\033[31mViolations found.\033[0m This script fixes nothing.\n'
exit $FAIL
