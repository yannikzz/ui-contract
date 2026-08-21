#!/bin/sh
# 正样本：同一份实跑产物，值全在 token 文件里，规范内 0 处色值。必须 PASS。
set -eu
cp "$(dirname "$0")/../fixtures/design-originate-real.md" design.md
