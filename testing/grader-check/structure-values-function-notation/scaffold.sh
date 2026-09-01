#!/bin/sh
# 负样本：真实 design.md 的 9 处色值机械改写成函数记法后摆进 layout.md 的位置。必须 FAIL——旧模式下它是绿的。
set -eu
cp "$(dirname "$0")/../fixtures/layout-with-function-notation.md" layout.md
