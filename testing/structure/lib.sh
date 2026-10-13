#!/bin/sh
# 三个有效性测试架（invariants / audit / colours）共享的注入测试回路。
#
# 架子只定义两件事，lib 出循环：
#   EFF_PREPARE <目标目录>   把夹具拷进去（各家的夹具不同：整树 / audit 夹具 / 示例线框）
#   EFF_RUN                  在目标目录里**运行被测系统**，输出到 stdout（供 needle 检查）
#
# 架子自己持有 FAIL / CASES 计数与 SH（dash 优先）的定义；lib 的函数在调用时
# 解析它们，所以先 source lib 还是先定义都一样。
#
# 为什么合成一份：sub() 的 python heredoc（BSD/GNU sed 兼容修法）曾抄了两份，
# ok/no 抄了三份，而 run 变体已经漂移——needle（「必须不出现」的那一半判定）
# 只存在于 audit 一份里。这份器械教给产品的正是 fix once, fixed everywhere。
# dev-only 工具，没有 shipped 文件「拷贝即源头」的约束。
#
# 每个用例：EFF_PREPARE → 注入一处违规 → EFF_RUN → 期望的退出码必须出现，
# needle 以 `!` 开头表示「必须**不**出现」。红的必须红，绿的必须绿——只测前者的话，
# 一个 `exit 1` 就能骗过整份测试。

ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }

# 用 python3 做文本替换：sed -i 在 BSD 与 GNU 下语法不同。
sub(){ # sub <文件> <旧> <新>
  python3 - "$1" "$2" "$3" <<'PY'
import io,sys
p,old,new=sys.argv[1],sys.argv[2],sys.argv[3]
s=io.open(p,encoding='utf-8').read()
if old not in s: sys.exit(9)
io.open(p,'w',encoding='utf-8').write(s.replace(old,new,1))
PY
}

run_out(){ # run_out <期望退出码> <必须出现|!必须不出现|空> <说明> <注入命令>
  want=$1; needle=$2; name=$3; mutate=$4
  CASES=$((CASES+1))
  W=$(mktemp -d) || { no "$name: mktemp 失败"; return; }
  EFF_PREPARE "$W" || { no "$name: 夹具准备失败"; rm -rf "$W"; return; }
  if ! ( cd "$W" && eval "$mutate" ); then
    no "$name: 注入本身失败（锚点变了？）"; rm -rf "$W"; return
  fi
  OUT=$( cd "$W" && EFF_RUN ); got=$?
  rm -rf "$W"
  if [ "$got" -ne "$want" ]; then
    no "$name — 期望 exit ${want}，实得 exit ${got}"; return
  fi
  case "$needle" in
    '' )   ok "$name" ;;
    '!'*)  if printf '%s' "$OUT" | grep -qF "${needle#!}"; then
             no "$name — 输出里不该出现「${needle#!}」"; else ok "$name"; fi ;;
    *)     if printf '%s' "$OUT" | grep -qF "$needle"; then ok "$name"
           else no "$name — 输出里没有「$needle」"; fi ;;
  esac
}

run_case(){ # run_case <期望退出码> <说明> <注入命令> —— 只看退出码的旧签名
  run_out "$1" "" "$2" "$3"
}
