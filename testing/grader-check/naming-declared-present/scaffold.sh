#!/bin/sh
# 正样本：2026-08-21 首次实跑 greenfield-originate 的真产物，声明表齐备（68 处关键词）。必须 PASS。
set -eu
cp "$(dirname "$0")/../fixtures/design-originate-real.md" design.md
