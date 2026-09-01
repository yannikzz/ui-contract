#!/bin/sh
# 正样本：一份真实产出的 layout.md，不含任何视觉值。必须 PASS。
set -eu
cp "$(dirname "$0")/../fixtures/layout-with-traces.md" layout.md
