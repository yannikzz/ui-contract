#!/bin/sh
# 所有不花钱的测试。任何开发者都能跑，无需 API key，无需 agent。
#   ./tests/run.sh
D="$(dirname "$0")"; FAIL=0
printf '\n\033[1m=== 结构不变量 ===\033[0m\n'; "$D/structure.sh" || FAIL=1
printf '\n'
[ $FAIL -eq 0 ] && printf '\033[32m全部通过\033[0m\n' || printf '\033[31m有失败\033[0m\n'
printf '行为层测试需要 API 额度：claude plugin eval .（见 evals/README.md）\n'
exit $FAIL
