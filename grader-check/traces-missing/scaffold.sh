#!/bin/sh
# 负样本：2026-08-19 实跑的**真实**产物，#5 修复之前的那一版。
# 决策树本身写得像样，但产物里一条追踪都没有——判据 2、3 判的正是这个。
# 当时 judge 判 FAIL 是对的，所以这份有 ground truth：这里必须 FAIL。
# 不要用「把正样本的附录 C 砍掉」来造负样本——试过，附录 B 里还留着
# 「追踪时发现这条普通需求走到了停」这类记述，judge 判 PASS 未必是错的。
set -eu
cp "$(dirname "$0")/../fixtures/layout-without-traces.md" layout.md
