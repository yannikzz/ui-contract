#!/bin/sh
# 与 handoff-correct 逐字相同：负样本的「负」全部在最后那段话里，不在盘上。
set -eu
cp "$(dirname "$0")/../fixtures/layout-with-traces.md" layout.md
