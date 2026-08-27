#!/bin/sh
# 铺一份真实的、完整的上游产出，让 wireframe 的前置门能通过。
#
# **取材于 `examples/admin-console/`，不自带副本。** 副本是结果，探针是器具——
# 同一条理由写在 `ui-contract-wireframe/implementation.md`：产出结果的器具不该
# 把结果一起背着。自带副本时这个目录是 8,248 词，现在是 300。
set -eu
R="$(dirname "$0")/../../../examples/admin-console"
[ -d "$R" ] || { echo "找不到 $R —— 探针取材于示例，示例没了就没有上游产物"; exit 1; }
cp "$R/layout.md" "$R/design.md" "$R/tsconfig.json" .
mkdir -p docs/ui-contract && cp "$R/docs/ui-contract/config.md" docs/ui-contract/
mkdir -p src/ui && cp "$R/src/ui/region.tsx" src/ui/ && cp "$R/src/ui-contract.assert.ts" src/
mkdir -p .ui-contract-local && cp "$R/.ui-contract-local/tokens.input.json" .ui-contract-local/ 2>/dev/null || true
[ -f "$R/src/tokens.css" ] && cp "$R/src/tokens.css" src/
ls -R . | head -30
