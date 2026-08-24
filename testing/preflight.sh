#!/bin/sh
# 网关 1：eval 套件的 schema 与每条判据的 coherence。**$0，不到一秒，零 agent run。**
#
# 靠的是 `--max-cost-usd 0`：成本上限在每次 run 之前检查，0 意味着一次都不跑，
# 但在跳过之前，套件已经被完整加载、校验、并对每条判据做过 coherence 检查。
# 实测这一步 `0 case(s) · 0s · $0.00`。
#
# 它替代的是一整类「只有实跑才暴露」的配置错误——`evals/README.md` 那十二个坑里
# 大半是这一类。坑 4（写文件的工具必须显式授权）尤其典型：那条是花实跑的钱买来的，
# 而 harness 在这一秒里免费打印同一件事。
#
# **不许只看退出码。** 量过：注入一个非法 frontmatter 键（`runz:`），CLI 正确地打印
# `✗ … unknown frontmatter key "runz"`，但退出码仍然是 2——cost ceiling 的 exit 2
# 盖掉了 load error 的 exit 1。只看退出码写出来的网关，就是又一条永远绿的检查。
# 所以判据是 stdout 的内容。
#
# **它不证明什么**：`--max-cost-usd 0` 的 JSON 文档里 `cases: []`（量过），
# 所以这一步看不见「哪些 case 被发现了」。目录与 case 的存在性由不变量 24 在磁盘上判。
cd "$(dirname "$0")/.." || exit 1
FAIL=0
ok(){   printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){   printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$1"; }

# `--allow-tools` 必须和真跑那条命令一致：不给的话每条判文件的判据都会报
# 「cannot pass with the granted tools」，网关会对着一个不存在的问题喊。
GRANT="Write Edit"

probe() { # probe <人话名字> <eval 目录>
  name=$1; dir=$2
  out=$(CLAUDE_CODE_WALNUT_SPIRE=1 claude plugin eval . \
          --eval-dir "$dir" --max-cost-usd 0 --ablation none --no-scaffold \
          --no-publish --allow-tools $GRANT 2>&1)

  # early access 没开：跳过而不是判失败——否则没拿到灰度的人连网关 0 都跑不完。
  # 但要喊得足够响，因为「静默跳过」正是这套测试要防的东西。
  if printf '%s' "$out" | grep -q 'currently in early access'; then
    warn "$name 跳过：这台机器的 \`plugin eval\` 早期访问没开（见 docs/reference/plugin-eval.md § Availability）"
    return 0
  fi

  if printf '%s' "$out" | grep -q 'No eval cases found'; then
    no "$name 一个 case 都没发现——eval 目录 \`$dir\` 对不上"; return 0
  fi

  # **先要有成功标记，再判坏字符串不在。** 这一条是被自己咬出来的：第一版只判
  # 「✗ / cannot pass / No eval cases found 都不出现」，于是把 GRANT 清空之后
  # CLI 报 `error: option '--allow-tools <tools...>' argument missing` 直接退出，
  # 三个坏字符串一个都不出现——网关绿着，而命令根本没跑起来。
  # 「坏东西没出现」和「好事发生了」是两件事，只判前者的检查在最坏的情况下最安静。
  if ! printf '%s' "$out" | grep -q 'Plugin under test:'; then
    no "$name 没解析出被测插件——命令没跑起来："; printf '%s\n' "$out" | head -3 | sed 's/^/      /'; return 0
  fi
  if ! printf '%s' "$out" | grep -q 'cost ceiling \$0 hit'; then
    no "$name 没走到成本上限那一步——套件没被完整加载："; printf '%s\n' "$out" | head -3 | sed 's/^/      /'; return 0
  fi
  bad=$(printf '%s' "$out" | grep '^✗')
  if [ -n "$bad" ]; then
    no "$name 有 case 加载/校验失败："; printf '%s\n' "$bad" | sed 's/^/      /'; return 0
  fi
  bad=$(printf '%s' "$out" | grep 'cannot pass with the granted tools' | sed 's/:.*//')
  if [ -n "$bad" ]; then
    no "$name 有判据在给定工具下不可能通过（harness 自己的 coherence 检查）："
    printf '%s\n' "$bad" | sort -u | sed 's/^/      /'; return 0
  fi
  ok "$name schema 与 coherence 全过"
}

echo "eval 套件的 schema 与判据 coherence（\$0，零 agent run）"
probe "testing/evals"        "testing/evals"
probe "testing/grader-check" "testing/grader-check"

printf '\n'
[ $FAIL -eq 0 ] && printf '\033[32m预检通过\033[0m\n' || printf '\033[31m预检有失败\033[0m\n'
exit $FAIL
