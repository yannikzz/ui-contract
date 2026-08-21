#!/bin/sh
# structure.sh 的每条断言**真的能失败**。
#
# 为什么需要这个：结构不变量守的东西有个共同点——破掉的时候输出完全正常。
# 一条断言「存在」和它「能失败」是两件事，读代码分不开它们，只有注入能。
# 而断言本身就是代码，也会有它自己那份「看着像在检查」的写法：
#   · 19 的第一版判「三个词在全文各出现一次」，注入后仍然绿；
#     第二版判「某一行同时含两组词」，一句随口散文照样满足（本文件 C 节）。
#   · 22 靠一对注释哨兵声明例外，而注释可以挪——END 搬到文件尾就是全文豁免。
# 两次都是断言写完、跑过、绿着，然后才发现它守不住。所以断言也要被注入验一遍。
#
# 每个用例：整树拷一份 → 注入一处违规 → 跑 structure.sh → 期望的退出码必须出现。
# 红的必须红，绿的必须绿——只测前者的话，一个 `exit 1` 就能骗过整份测试。
cd "$(dirname "$0")/.." || exit 1
FAIL=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }

D="skills/ui-contract-design/SKILL.md"
T="skills/ui-contract-design/assets/theme-studio.html.template"
W_TPL="skills/ui-contract-wireframe/assets/wire.tsx.template"
for f in tests/structure.sh "$D" "$T" "$W_TPL" examples/README.md; do
  [ -f "$f" ] || { no "找不到 $f"; exit 1; }
done

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
run_case(){ # run_case <期望退出码> <说明> <注入命令>
  want=$1; name=$2; mutate=$3
  CASES=$((CASES+1))
  W=$(mktemp -d) || { no "$name: mktemp 失败"; return; }
  # 断言判的是仓库自身，所以整树拷一份（不到 1MB）。.git 在 worktree 下是个
  # 文件而不是目录，拷过去无害，但 structure.sh 一个字都不读它，删掉更干净。
  cp -R . "$W"/ 2>/dev/null && rm -rf "$W/.git" || { no "$name: 夹具准备失败"; rm -rf "$W"; return; }
  if ! ( cd "$W" && eval "$mutate" ); then
    no "$name: 注入本身失败（锚点变了？）"; rm -rf "$W"; return
  fi
  ( cd "$W" && ./tests/structure.sh >/dev/null 2>&1 )
  got=$?
  rm -rf "$W"
  if [ "$got" -eq "$want" ]; then ok "$name"
  else no "$name — 期望 exit ${want}，实得 exit ${got}"; fi
}

echo "A. 基线：未注入时必须全绿"
run_case 0 "干净的整树拷贝 exit 0" "true"

echo "B. 19-23 各注入一处违规，必须转红"
run_case 1 "19 · 身份表不再说 tokens.input.json 是输入记录" \
  "sub $D '(an input record)' '(a record)'"
run_case 1 "20 · ROLE 映射表里填进了 token 名" \
  "sub $T \"pageBg:'', pageFg:''\" \"pageBg:'background', pageFg:'foreground'\""
run_case 1 "21 · 器具样张里出现 IA 载体" \
  "sub $T '<body' '<body><nav class=\"x\">demo</nav'"
run_case 1 "22 · 哨兵块外的产品组件写死了品牌色" \
  "sub $W_TPL 'export function Badge({ children }: { children: ReactNode }) {' 'export function Badge({ children }: { children: ReactNode }) {
  const leak = \"#2563eb\"; void leak;'"
run_case 1 "22 · SKIN 出厂就填好了 token 名" \
  "sub $W_TPL \"'--wire-surface': ''\" \"'--wire-surface': 'background'\""
run_case 1 "23 · 模板新增导出，示例与 README 都没提" \
  "printf '\nexport function InjectedThing() { return null }\n' >> $W_TPL"

echo "C. 断言自己的绕过口"
# 19：把整张身份表删掉，末尾补一句随口的散文。第二版断言只要求「某一行同时含
# 两组词」，这一句就满足——而「谁说了算」根本没被说出来。锚点因此钉在表格结构
# 和冲突判定那一列上：does not count / wins 是散文说不出来的。
run_case 1 "19 · 删掉身份表，改用一句随口的散文" \
  "sub $D '| \`tokens.input.json\` | where the user left the knobs (an input record) | does not count |
| the token file | the values that are currently correct | wins |' '' && printf '\ntokens.input.json is an input record. The token file holds values that are currently correct.\n' >> $D"
# 22：哨兵只是两行注释，挪一下在 review 里长得像格式调整，而挪完整份文件都进
# 豁免区。守法是「块外必须还有产品组件」——inspect 装置在块内，产品表面在块外。
run_case 1 "22 · 把 INSPECT CHROME END 推到文件尾（全文豁免）" \
  "sub $W_TPL '// ── INSPECT CHROME END ──────────────────────────────────────
' '' && sub $W_TPL 'export function Badge({ children }: { children: ReactNode }) {' 'export function Badge({ children }: { children: ReactNode }) {
  const leak = \"#2563eb\"; void leak;' && printf '\n// ── INSPECT CHROME END ──────────────────────────────────────\n' >> $W_TPL"
# 同一个口子的另一种走法：不挪边界，另开一对把违规圈进去。
# ⚠ 与上面两条不同，**这条在断言改掉之前就已经是红的**：正则取的是第一个 BEGIN
# 到第一个 END，新开的一对落在原 END 之后，根本选不中。它留在这里是对照——
# 记录这条路本来就走不通，免得下一个人误以为「各恰好一次」是它的修复。
# 那句检查守的是另一种组合：先把原哨兵删掉或挪走，再另起一对。成本一行，留着。
run_case 1 "22 · 另开一对哨兵，把品牌色圈进豁免区（旧断言下也红，对照用）" \
  "sub $W_TPL 'export function Badge({ children }: { children: ReactNode }) {' '// ── INSPECT CHROME BEGIN ──
export function Badge({ children }: { children: ReactNode }) {
  const leak = \"#2563eb\"; void leak;
// ── INSPECT CHROME END ──'"

printf '\n'
# 已知抓不到、且刻意不写成用例的四处——写成用例就得给它们一个期望退出码，
# 而 0 的意思是「这样做没问题」，那是假话；哪天有人把口子堵上，用例还会错误地转红。
# 记在这里，因为不写下来的话，下一个读这份测试的人会以为覆盖是完整的：
#   · 往 NEUTRAL 里加品牌色（NEUTRAL 内本来就允许写值，「加进去的是不是灰」只能人评审，PR #13 已声明）
#   · 用 <aside> 之类不在第 21 条关键词名单里的 IA 载体
#   · 用 crimson / white 这类 CSS 具名颜色写死值（第 22 条的正则只认 hex/rgb/oklch/hsl 与 tailwind 色阶）
#   · 改现有导出的实现而不动它的名字（第 23 条只比对导出名的集合）
[ $FAIL -eq 0 ] && printf '\033[32m%s 个用例：断言全部能按预期红/绿\033[0m\n' "$CASES" \
                || printf '\033[31m有断言没按预期红/绿\033[0m\n'
exit $FAIL
