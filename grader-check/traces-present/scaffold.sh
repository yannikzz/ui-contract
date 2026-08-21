#!/bin/sh
# 正样本：一份真实产出的 layout.md，附录 C 里两类追踪齐备。
set -eu
cp "$(dirname "$0")/../fixtures/layout-with-traces.md" layout.md
