#!/bin/sh
# invariants.sh 的每条断言**真的能失败**。
#
# 覆盖范围（这一行是承诺，别让它变成散文）：**1–30 全部有用例**。
# 其中 13 与 27 是 warn 档，用例期望 exit 0——它们证明的是「这条不改退出码」，
# 那是声明过的宽，不是漏掉。
#
# 这句话在 2026-08-24 之前是假的：那时只覆盖 19 以后，而开头照样写着「每条断言」。
# 实测过——把检查 1 整段注释掉，本文件全绿并打印「断言全部能按预期红/绿」。
# 一份只覆盖一半的证据配一句全称承诺，正是这份测试存在的理由本身。
# 加检查时**同时**加用例；只加检查不加用例，等于把这句话又变回散文。
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
cd "$(dirname "$0")/../.." || exit 1
FAIL=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }

D="skills/ui-contract-design/SKILL.md"
T="skills/ui-contract-design/assets/theme-studio.html.template"
W_TPL="skills/ui-contract-wireframe/assets/wire.tsx.template"
BL_GRD="testing/evals/greenfield-originate/graders/no-framework-default-values.md"
for f in testing/structure/invariants.sh "$D" "$T" "$W_TPL" "$BL_GRD" examples/README.md; do
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

# 同上，但换掉**全部**出现处。`sub` 只换第一处，对「grep 找得到就算数」的断言不够：
# 换掉一处，剩下的照样能被 grep 到，断言green，注入等于没做。
suball(){ # suball <文件> <旧> <新>
  python3 - "$1" "$2" "$3" <<'PY'
import io,sys
p,old,new=sys.argv[1],sys.argv[2],sys.argv[3]
s=io.open(p,encoding='utf-8').read()
if old not in s: sys.exit(9)
io.open(p,'w',encoding='utf-8').write(s.replace(old,new))
PY
}

# 在 <锚点> 后面塞 n 个字符，用来撑爆长度类断言（检查 3、8）。
pad(){ # pad <文件> <锚点> <字符数>
  python3 - "$1" "$2" "$3" <<'PY'
import io,sys
p,anchor,n=sys.argv[1],sys.argv[2],int(sys.argv[3])
s=io.open(p,encoding='utf-8').read()
if anchor not in s: sys.exit(9)
io.open(p,'w',encoding='utf-8').write(s.replace(anchor, anchor+('x'*n), 1))
PY
}

CASES=0
run_case(){ # run_case <期望退出码> <说明> <注入命令>
  want=$1; name=$2; mutate=$3
  CASES=$((CASES+1))
  W=$(mktemp -d) || { no "$name: mktemp 失败"; return; }
  # 断言判的是仓库自身，所以整树拷一份——但**要排掉 node_modules 与 .git**。
  #
  # 这里原来写着「不到 1MB」，而量出来是 92MB：`examples/admin-console/node_modules`
  # 一个人占 85MB。用例涨到 46 条之后，一次跑要拷四个多 G，整份 0c 从秒级变成分钟级。
  # 那句「不到 1MB」曾经是真的，没人再量过——和这份测试抓的其他东西是同一种失效，
  # 只不过代价是时间而不是正确性。所以这里写的是**为什么可以排**，不是又一个数字：
  # invariants.sh 只读 skills/、docs/adr/、testing/、examples/README.md、README.md
  # 与 .claude-plugin/，`node_modules` 与 `.git` 一个字都不读。
  #
  # 用 tar 管道而不是 `cp -R` + 删：BSD 与 GNU 的 tar 都认 --exclude，
  # 而 cp 没有可移植的排除写法。
  tar -cf - --exclude=node_modules --exclude=.git . 2>/dev/null | ( cd "$W" && tar -xf - ) \
    || { no "$name: 夹具准备失败"; rm -rf "$W"; return; }
  if ! ( cd "$W" && eval "$mutate" ); then
    no "$name: 注入本身失败（锚点变了？）"; rm -rf "$W"; return
  fi
  ( cd "$W" && ./testing/structure/invariants.sh >/dev/null 2>&1 )
  got=$?
  rm -rf "$W"
  if [ "$got" -eq "$want" ]; then ok "$name"
  else no "$name — 期望 exit ${want}，实得 exit ${got}"; fi
}

echo "A. 基线：未注入时必须全绿"
run_case 0 "干净的整树拷贝 exit 0" "true"

echo "B0. 1-18 各注入一处违规（这一档此前整个是空的）"
# 为什么补：这个文件第 2 行写着「structure.sh 的每条断言真的能失败」，而在补上之前
# 它只覆盖 19 以后。实测过：把检查 1 整段注释掉，本文件仍然全绿并打印
# 「断言全部能按预期红/绿」——**一句全称承诺，配着一份只覆盖一半的证据**。
# 那正是这份测试存在的理由本身。
#
# 每条尽量只踩一条断言：注入点选在别的断言读不到的地方，锚点旁边写明为什么不会串。
run_case 1 "1 · README 索引与磁盘不一致（改索引里的一个包名）" \
  "sub README.md '](skills/ui-contract-glossary/SKILL.md)' '](skills/ui-contract-glossaryx/SKILL.md)'"
run_case 1 "2 · frontmatter name 与目录名不一致" \
  "sub skills/ui-contract-glossary/SKILL.md 'name: ui-contract-glossary' 'name: ui-contract-glossaryx'"
# 撑爆的是入口包：检查 8 只在入口 description **过短**时判红，所以这一条不会串到 8。
run_case 1 "3 · description 超过 1024 字符（921 + 200）" \
  "pad skills/ui-contract/SKILL.md 'description: ' 200"
run_case 1 "4 · 某个技能标了 disable-model-invocation" \
  "printf '\ndisable-model-invocation: true\n' >> skills/ui-contract-glossary/SKILL.md"
run_case 1 "5 · 原语包里出现 UI 词汇" \
  "printf '\n界面\n' >> skills/decision-record/SKILL.md"
# 目标真实存在，所以检查 7 是绿的——这一条单独证明 6 能红。
run_case 1 "6 · 出现 ../ 跨包相对路径引用" \
  "printf '\n[x](../ui-contract-layout/SKILL.md)\n' >> skills/ui-contract-glossary/SKILL.md"
# 反过来：不带 ../，所以检查 6 绿，只有 7 红。
run_case 1 "7 · 包内 markdown 链接断了" \
  "printf '\n[x](nope.md)\n' >> skills/ui-contract-glossary/SKILL.md"
# 非入口包 354 + 300 = 654 > 600（检查 8 红），而 654 < 1024（检查 3 仍绿）。
run_case 1 "8 · 非入口包的 description 涨到抢触发的长度（354 + 300）" \
  "pad skills/ui-contract-glossary/SKILL.md 'description: ' 300"
run_case 1 "9 · 有提问的单元没接访谈纪律（CLAUDE.md 记着的那次真实失效）" \
  "suball skills/ui-contract-setup/SKILL.md 'call the Skill tool with \"decision-interview\"' 'run the interview'"
run_case 1 "10 · 能力包丢了前置门" \
  "sub skills/ui-contract-layout/SKILL.md '## Preconditions' '## Precondition'"
run_case 1 "11 · 产出文字的包没接语言纪律" \
  "suball skills/ui-contract-setup/SKILL.md 'call the Skill tool with \"deliverable-language\"' 'write in their language'"
run_case 1 "12 · 技能包里混进了测试目录（install.sh 会整包发给用户）" \
  "mkdir -p skills/ui-contract-glossary/tests && printf 'x\n' > skills/ui-contract-glossary/tests/keep.md"
# 13 是 warn 档：退出码证明不了它，只能证明它**不**改退出码（与 27 同一处理）。
run_case 0 "13 · SKILL.md 缩到 30 行以下 → warn，退出码不变（声明过的宽）" \
  "sed -n '1,25p' skills/ui-contract-glossary/SKILL.md > .t && mv .t skills/ui-contract-glossary/SKILL.md"
# 必须换掉全部出现处：只换一处的话 grep -q 照样命中，注入等于没做。
run_case 1 "14 · 能力包不再声明从 config 的路径表读落点" \
  "suball skills/ui-contract-baseline/SKILL.md 'paths table' 'path table'"
run_case 1 "15 · 大纲里没有 Appendix C（追踪表失去落点）" \
  "sub skills/ui-contract-layout/layout-md-outline.md '## Appendix C' '## Appendix D'"
run_case 1 "16 · 体检技能的退出码表里没有 exit 3 那一行" \
  "sub skills/ui-contract-audit/SKILL.md '| 3 | a contract' '| 33 | a contract'"
# 改的是 pattern 而不是正文：`naming-declared` 是 regex 判据，17 对它比的就是 pattern，
# 往正文里加字它一个字都不看（第一版这么写，绿着，正是这份测试要抓的形状）。
run_case 1 "17 · 一条 regex 判据的三份拷贝分了家（pattern 被改窄）" \
  "sub testing/evals/greenfield-originate/graders/naming-declared.md 'borrowed|this project|not used' 'borrowed|this project'"
# 另一半：criteria 型判据的拷贝也要能分家，两种取值路径不是同一段代码。
# 必须改在 `criteria: |` 的**块内**（六格缩进）：往文件尾追加一行是块外，17 取不到，
# 注入等于没做——第一版就是这么写的，绿着。
run_case 1 "17 · 一条 llm 判据的三份拷贝分了家（criteria 块内被改）" \
  "sub testing/grader-check/asbuilt-descriptive/case.yaml '量出缺口。' '量出缺口（只有这一份这么写）。'"
run_case 1 "18 · 体检模板里又出现了行式匹配标签的 grep" \
  "printf '\ngrep -rn \"<div\" \"\$SRC\"\n' >> skills/ui-contract-audit/assets/audit.sh.template"

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

echo "B2. 24-27 各注入一处违规，必须转红"
# 这四条是这次重构新加的。第 26 条的第一版就是指纹——它只认「不变量 N」「检查 N」，
# 而**真实发生过的那种措辞**（「invariants.sh 加了第 24 条」）原样穿过去。
# 下面第三个用例就是那一种，它是这四条里唯一有事故先例的。
run_case 1 "24 · manifest 的 experimental.evals 指向不存在的目录" \
  "sub .claude-plugin/plugin.json '\"evals\": \"testing/evals\"' '\"evals\": \"testing/nope\"'"
run_case 1 "25 · 判据 input_match 点名了一个不存在的包" \
  "sub testing/evals/greenfield-mobile/graders/layout-skill-fired.md 'ui-contract-layout\"' 'ui-contract-laypout\"'"
run_case 1 "26 · ADR 说「invariants.sh 加了第 99 条」（PR #13 那种措辞）" \
  "printf '\ninvariants.sh 加了第 99 条。\n' >> docs/adr/0006-wireframe-skin-preview.md"
run_case 1 "26 · ADR 说「不变量 99」" \
  "printf '\n不变量 99 守着这件事。\n' >> docs/adr/0006-wireframe-skin-preview.md"
# 27 是 warn，按设计不改退出码——所以它的用例期望 0。这不是「这样做没问题」，
# 是「这条检查明说了自己不判失败」，两者的区别在于后者是**声明过的**。
run_case 0 "27 · ADR 提到一个不存在的路径 → warn，退出码不变（声明过的宽）" \
  "printf '\n见 \`testing/nonexistent.sh\`。\n' >> docs/adr/0006-wireframe-skin-preview.md"

run_case 1 "28 · 技能调用指向本插件之外的包（真实发生过的那种写法）" \
  "printf '\nCall the Skill tool with \"frontend-design\".\n' >> skills/ui-contract-design/originate.md"
run_case 1 "28 · 同上，带 plugin: 前缀（前缀不该让它蒙混过去）" \
  "printf '\nCall the Skill tool with \"frontend-design:frontend-design\".\n' >> skills/ui-contract-design/originate.md"

# 30 用的正是 ADR-0008 改名之后真实留下的那种引用——它在 skills/ 里躺了整整一轮 review
# 才被发现，而 skills/ 是唯一会安装到用户机器的目录。
run_case 1 "30 · skills/ 里指向改名前的 tests/structure.sh（真实发生过的那种）" \
  "printf '\n见 \`tests/structure.sh\`。\n' >> skills/ui-contract-wireframe/implementation.md"
run_case 1 "30 · examples/ 里指向一个不存在的开发树路径" \
  "printf '\n见 \`testing/nonexistent.sh\`。\n' >> examples/README.md"

# 31 两边各注入一次：只测一个方向的话，「谁改了谁」这件事只被守住一半。
run_case 1 "31 · 器具给基础对加了别名，体检没跟" \
  "sub skills/ui-contract-design/assets/theme-studio.html.template 'background|page|surface' 'background|page|surface|canvas'"
run_case 1 "31 · 体检改了基础对名单，器具没跟" \
  "sub skills/ui-contract-audit/assets/audit.sh.template 'foreground|text' 'foreground|text|body'"

# 29 两个方向分开注入：漏判和假阳的后果不同，一条用例盖不住两种。
run_case 1 "29 · 产品的黑名单加了一个色值，判据 pattern 没跟（静默漏判）" \
  "sub skills/ui-contract-design/originate.md '#1976d2  #2196f3' '#1976d2  #2196f3  #4285f4'"
run_case 1 "29 · 判据 pattern 少了一个色值，产品名单没变（静默漏判，反向）" \
  "sub $BL_GRD '#3b82f6|#2563eb|' '#3b82f6|'"
run_case 1 "29 · 判据 pattern 加了个宽松分支（比对通过，行为全变）" \
  "sub $BL_GRD '#3b82f6|' 'blue|#3b82f6|'"

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

# 21 与 22 各自的名单/记法缺口：违规原封不动，只换一种写法。
# 两条都是「名单式检查」的通病——名单永远差一个，所以补的时候连同**没补的**
# 一起写进断言注释里，让下一个人看得见边界在哪，而不是以为它守住了全部。
run_case 1 "22 · 把产品组件整段搬进哨兵块，在块内写死品牌色（一次搬一个）" \
  "python3 - <<'INJ'
import re
p='skills/ui-contract-wireframe/assets/wire.tsx.template'
s=open(p,encoding='utf-8').read()
m=re.search(r'\nexport function Btn\(\{.*?\n\}\n', s, re.S)
blk=m.group(0).rstrip('\n')+chr(10)+\"const BTN_BRAND = '#2563eb'\"+chr(10)
s=s[:m.start()]+chr(10)+s[m.end():]
s=s.replace('// ── INSPECT CHROME END', blk+'// ── INSPECT CHROME END',1)
open(p,'w',encoding='utf-8').write(s)
INJ"
run_case 1 "21 · 用 <aside> 代替 <nav>（名单外的 IA 载体）" \
  "sub $T '<body' '<body><aside class=\"panel\">nav</aside'"
run_case 1 "22 · 用 CSS 具名颜色写死值（记法外的颜色）" \
  "sub $W_TPL 'export function Badge({ children }: { children: ReactNode }) {' 'export function Badge({ children }: { children: ReactNode }) {
  const leak = { color: \"crimson\" }; void leak;'"

printf '\n'
# 已知抓不到、且刻意不写成用例的两处——写成用例就得给它们一个期望退出码，
# 而 0 的意思是「这样做没问题」，那是假话；哪天有人把口子堵上，用例还会错误地转红。
# 记在这里，因为不写下来的话，下一个读这份测试的人会以为覆盖是完整的：
#   · 往 NEUTRAL 里加品牌色（NEUTRAL 内本来就允许写值，「加进去的是不是灰」只能人评审，PR #13 已声明）
#   · 改现有导出的实现而不动它的名字（第 23 条只比对导出名的集合。这一条
#     是故意宽的：示例是实跑产出，逐行比对等于逐行逆向维护它，而这会把它变成手绘插图）
[ $FAIL -eq 0 ] && printf '\033[32m%s 个用例：断言全部能按预期红/绿\033[0m\n' "$CASES" \
                || printf '\033[31m有断言没按预期红/绿\033[0m\n'
exit $FAIL
