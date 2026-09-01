#!/bin/sh
# 不花钱的两道网关。任何开发者都能跑，无需 API key，无需 agent 实跑。
#   ./testing/run.sh
#
# 四道网关按成本排，前一道是后一道的硬前提。本脚本只跑前两道——后两道花钱，
# 各自的命令写在 testing/evals/README.md 与 testing/grader-check/README.md：
#
#   0  testing/structure/       磁盘结构 + 断言自己能失败        $0        秒
#                            （含 audit.sh 与 check-colours.sh 两个模板脚本的注入测试）
#   1  testing/preflight.sh     eval 套件 schema + 判据 coherence $0        <1s
#   2  testing/grader-check/    判据有没有判别力                  ~$0.06/case
#   3  testing/evals/           插件的实际效果                    ~$18
D="$(dirname "$0")"; FAIL=0
printf '\n\033[1m=== 网关 0a · 结构不变量 ===\033[0m\n';        "$D/structure/invariants.sh" || FAIL=1
printf '\n\033[1m=== 网关 0b · 体检脚本的检查真的能失败 ===\033[0m\n'; "$D/structure/audit-effectiveness.sh" || FAIL=1
printf '\n\033[1m=== 网关 0c · 结构断言真的能失败 ===\033[0m\n'; "$D/structure/invariants-effectiveness.sh" || FAIL=1
printf '\n\033[1m=== 网关 0d · 线框颜色脚本的检查真的能失败 ===\033[0m\n'; "$D/structure/colours-effectiveness.sh" || FAIL=1
printf '\n\033[1m=== 网关 1 · eval 套件预检 ===\033[0m\n';       "$D/preflight.sh" || FAIL=1
printf '\n'
[ $FAIL -eq 0 ] && printf '\033[32m全部通过\033[0m\n' || printf '\033[31m有失败\033[0m\n'
printf '网关 2 / 3 要 API 额度：见 testing/grader-check/README.md 与 testing/evals/README.md\n'
exit $FAIL
