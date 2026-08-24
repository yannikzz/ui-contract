#!/bin/sh
# 负样本：examples/admin-console 的真实产出，产出时声明表这个概念还不存在（0 处关键词）。必须 FAIL。
set -eu
cp "$(dirname "$0")/../fixtures/design-no-declaration.md" design.md
