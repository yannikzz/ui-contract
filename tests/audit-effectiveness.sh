#!/bin/sh
# audit.sh.template 的每条检查**真的能失败**。
#
# 为什么需要这个：两轮 code review 在那个脚本里找出 4 条永远返回绿的检查。
# 每一条单独读都像在工作——写着 grep、写着 drift 分支、注释也讲得通。
# 它们的共同病根是 JSX 属性换行：调用点一多行，行式匹配就看不见整个标签。
# 一条检查「存在」和它「能失败」是两件事，只有注入能分开它们。
#
# 每个用例：拷夹具 → 注入一处违规 → 跑脚本 → 期望的退出码必须出现。
# 红的必须红，绿的必须绿——只测前者的话，一个 `exit 1` 就能骗过整份测试。
cd "$(dirname "$0")/.." || exit 1
FAIL=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }

TEMPLATE="skills/ui-contract-audit/assets/audit.sh.template"
FIXTURE="tests/fixtures/audit-project"
[ -f "$TEMPLATE" ] || { no "找不到 $TEMPLATE"; exit 1; }
[ -d "$FIXTURE" ]  || { no "找不到 $FIXTURE"; exit 1; }

# 模板自称要能在 dash 下跑，所以优先用 dash 跑，顺便守住这条。
SH=$(command -v dash 2>/dev/null || command -v sh)

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

CASES=0
# run_case 只看退出码。**warn 不改退出码**，所以一条只报 warn 的检查用 run_case
# 是证明不了的——它挂了和它没挂，退出码一模一样。而「看起来在工作、其实永远返回绿」
# 正是这份测试的由来，加了 warn 档就等于给那个病根开了一个新入口。这一版看输出。
# needle 以 `!` 开头表示「必须**不**出现」——用来钉住「不许喊狼来了」的那一半。
run_out(){ # run_out <期望退出码> <必须出现|!必须不出现> <说明> <注入命令>
  want=$1; needle=$2; name=$3; mutate=$4
  CASES=$((CASES+1))
  W=$(mktemp -d) || { no "$name: mktemp 失败"; return; }
  cp -R "$FIXTURE"/. "$W"/ && cp "$TEMPLATE" "$W/audit.sh" || { no "$name: 夹具准备失败"; rm -rf "$W"; return; }
  if ! ( cd "$W" && eval "$mutate" ); then
    no "$name: 注入本身失败（夹具里的锚点变了？）"; rm -rf "$W"; return
  fi
  OUT=$( cd "$W" && "$SH" ./audit.sh 2>&1 ); got=$?
  rm -rf "$W"
  if [ "$got" -ne "$want" ]; then
    no "$name — 期望 exit ${want}，实得 exit ${got}"; return
  fi
  case "$needle" in
    '!'*) if printf '%s' "$OUT" | grep -qF "${needle#!}"; then
            no "$name — 输出里不该出现「${needle#!}」"; else ok "$name"; fi ;;
    *)    if printf '%s' "$OUT" | grep -qF "$needle"; then ok "$name"
          else no "$name — 输出里没有「$needle」"; fi ;;
  esac
}

run_case(){ # run_case <期望退出码> <说明> <注入命令>
  want=$1; name=$2; mutate=$3
  CASES=$((CASES+1))
  W=$(mktemp -d) || { no "$name: mktemp 失败"; return; }
  cp -R "$FIXTURE"/. "$W"/ && cp "$TEMPLATE" "$W/audit.sh" || { no "$name: 夹具准备失败"; rm -rf "$W"; return; }
  if ! ( cd "$W" && eval "$mutate" ); then
    no "$name: 注入本身失败（夹具里的锚点变了？）"; rm -rf "$W"; return
  fi
  ( cd "$W" && "$SH" ./audit.sh >/dev/null 2>&1 )
  got=$?
  rm -rf "$W"
  if [ "$got" -eq "$want" ]; then ok "$name"
  else no "$name — 期望 exit ${want}，实得 exit ${got}"; fi
}

echo "A. 基线：未注入时必须全绿"
run_case 0 "干净的夹具 exit 0" "true"
run_case 0 "token 文件里的色值不算漂移（检查 3 的对照）" \
  "printf '  --accent: #ff8800;\n' >> src/tokens.css"

echo "B. 每条检查各注入一处违规，必须转红"
run_case 1 "检查 1 · **多行**调用点的区域名不在白名单" \
  "sub src/App.tsx 'id=\"main.pagehead\"' 'id=\"totally-made-up-region\"'"
run_case 1 "检查 1 · **单行**调用点的区域名不在白名单" \
  "sub src/App.tsx 'id=\"nav\" className' 'id=\"not-on-the-list\" className'"
run_case 1 "检查 2 · 多行调用点里用 as any 绕过 RegionId" \
  "sub src/App.tsx 'id=\"app-shell\"' 'id={(\"app-shell\" as string) as any}'"
run_case 1 "检查 2 · 用 as RegionId 强转" \
  "sub src/App.tsx 'id=\"nav\" className' 'id={x as RegionId} className'"
run_case 1 "检查 2b · **单行**手写 data-region 绕过结构容器" \
  "sub src/App.tsx '<Region id=\"inspector\"' '<div data-region=\"inspector\"'"
# 手写 marker 的真实形态就是多行的：属性一超过一个，prettier 就把标签拆开，
# 于是 `<div` 和 `data-region="…"` 落在两行，行式匹配一个都看不见。
# 检查 1 早就为此配了单行 / 多行两个用例；2b 当初只注入了单行那种，
# 于是它在「能失败」这件事上其实从没被证明过。
run_case 1 "检查 2b · **多行**手写 data-region 绕过结构容器" \
  "sub src/App.tsx '<Region id=\"inspector\"' '<div
            data-region=\"inspector\"
           '"
run_case 1 "检查 3 · 非 token 的样式表里有硬编码色值" \
  "printf '.card { background: #123456; }\n' > src/feature.css"
run_case 1 "检查 4 · 视觉规范里写死了色值" \
  "printf '\n正文色 #445566。\n' >> design.md"
run_case 1 "检查 5 · 白名单某行没写「禁止放什么」" \
  "sub layout.md '| \`inspector\` | 单对象属性 | 列表、批量动作 |' '| \`inspector\` | 单对象属性 |  |'"
run_case 1 "检查 8 · 一对 surface/-foreground 的对比度低于 design.md 的阈值" \
  "sub src/tokens.css '--card-foreground: #1a1a1a;' '--card-foreground: #f2f2f2;'"
run_case 1 "检查 6 · 白名单里的区域名从没被渲染" \
  "sub src/ui/region.tsx \"  | 'inspector'\" \"  | 'inspector'
  | 'never-rendered-anywhere'\" && sub src/ui/region.tsx '  inspector: {' \"  'never-rendered-anywhere': { label: 'X', desc: '禁止 X。' },
  inspector: {\""

echo "B2. warn 档的检查（退出码证明不了，只能看输出）"
# 干净夹具一条 warn 都不该有。少了这条，下面两条「能响」就没有意义——
# 一条永远在响的检查和一条永远不响的检查，同样没人会再读它的输出。
run_out 0 '!warning(s)' "基线 · 干净夹具零 warn（这两条检查不许喊狼来了）" "true"
run_out 0 'declared but not in the token file' \
  "检查 7 · 声明表里有、token 文件里没有（断链）" \
  "printf '| \`ghost-token\` | this project |\n' >> design.md"
run_out 0 'in the token file but not declared' \
  "检查 7 · token 文件里有、声明表里没有（漏声明）" \
  "printf '  --undeclared-token: #333333;\n' >> src/tokens.css"
# 这条钉住的是一个**刻意的降级**：脚本只读得懂十六进制，而借来的那套命名当前
# 写成 oklch()。看不见的时候必须报 skip，不许打绿勾——绿勾在这里就是假绿，
# 正是这份脚本存在的理由。改这条之前先想清楚你是不是把假绿放了进来。
run_out 0 'non-hex notations are not read here' \
  "检查 8 · token 全是 oklch 时报 skip，不许打绿勾" \
  "sub src/tokens.css '--card: #ffffff;' '--card: oklch(1 0 0);' && sub src/tokens.css '--card-foreground: #1a1a1a;' '--card-foreground: oklch(0.2 0 0);'"

echo "C. 无契约时的退出码"
run_case 2 "没有 layout.md、也没有 config.md → exit 2（真的没东西可检）" "rm -f layout.md"
# 「没东西可检」和「配置说有、脚本找不到」必须分开。共用 exit 2 时后者会伪装成前者：
# 输出是一句平静的 "there is no contract to check"，读起来像通过，实际是路径失配。
# 夹具本身不含 config.md（它刻意最小），所以这一条在临时副本里现造一个。
run_case 3 "没有 layout.md 但有 config.md → exit 3（路径表与脚本对不上）" \
  "mkdir -p docs/ui-contract && printf '# UI contract — configuration\n' > docs/ui-contract/config.md && rm -f layout.md"
# 反方向才是会**绿着挂**的那个：config 把规范搬走了，根目录还留着一份旧的，
# 于是下面每条检查都认认真真审了一份被弃用的文件，最后打印 "No drift found."
# 注意夹具里这一行的第三列（Default）仍然写着 `layout.md`——脚本只读第二列（Path），
# 读错列的话这条用例会绿，这条用例存在的意义就是钉住这一点。
run_case 3 "有 layout.md，但 config 的路径表指向别处 → exit 3（别审一份没人认的文件）" \
  "mkdir -p docs/ui-contract && printf '| 结构规范 | \`docs/spec/layout.md\` | \`layout.md\` at the repo root |\n' > docs/ui-contract/config.md"
# setup 允许项目给规范改名，所以「路径表指向另一个文件名」和「指向另一个目录」是
# 两件事——后者脚本的旧路径会落空，前者旧路径照样指着一个真文件，于是七条检查全跑完、
# 报 "No drift found."。按 Path 列去猜「哪个路径长得像 layout.md」正好漏掉这一种。
run_case 3 "路径表把规范改了名，旧 layout.md 还在原地 → exit 3（最会假绿的一种）" \
  "mkdir -p docs/ui-contract && printf '| 结构规范 | \`UI-STRUCTURE.md\` | \`layout.md\` at the repo root |\n' > docs/ui-contract/config.md"
run_case 0 "config 的路径表与脚本一致时不误报（这条检查不许喊狼来了）" \
  "mkdir -p docs/ui-contract && printf '| 结构规范 | \`layout.md\` | \`layout.md\` at the repo root |\n' > docs/ui-contract/config.md"

printf '\n'
[ $FAIL -eq 0 ] && printf '  \033[32m%s 个用例全部符合预期（%s）\033[0m\n' "$CASES" "$(basename "$SH")" \
                || printf '  \033[31m有检查名存实亡\033[0m\n'
exit $FAIL
