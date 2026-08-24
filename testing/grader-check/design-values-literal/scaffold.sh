#!/bin/sh
# 负样本：existing-admin 夹具里的「现状」design.md，含 9 处硬编码色值——含值是它的本质属性，不是人为破坏。必须 FAIL。
set -eu
cp "$(dirname "$0")/../fixtures/design-with-literals.md" design.md
