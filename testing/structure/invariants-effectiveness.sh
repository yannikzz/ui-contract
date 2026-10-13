#!/bin/sh
# invariants.sh 的每条断言**真的能失败**。
#
# 覆盖范围（这一行是承诺，别让它变成散文）：**1–36 全部有用例**。
#
# 2026-08-25：这一行**真的变成过散文**——它写着 1–30 而检查已经有 31 条，没有任何东西
# 在比对。现在由 invariants.sh 第 32 条机检：每条检查都有用例，且这一行的上界等于实际条数。
# 一句自称是承诺的话，靠人守就不是承诺。
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
#   · 22 原先靠一对注释哨兵声明例外，而注释可以挪——END 搬到文件尾就是全文豁免。
#     ADR-0012 把锚换成一个文件之后，这四条用例也跟着重写了：锚变了，攻击面就变了。
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
W_APP="skills/ui-contract-wireframe/assets/inspect.tsx.template"
BL_GRD="testing/evals/greenfield-originate/graders/no-framework-default-values.md"
for f in testing/structure/invariants.sh "$D" "$T" "$W_TPL" "$W_APP" "$BL_GRD" examples/README.md; do
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
# 锚点带上开引号：这个 description 是加了引号的，塞在引号外面造出来的是坏 YAML，
# 那样这条会因为第 36 条红，而不是因为长度——证明不了检查 3 自己能红。
run_case 1 "3 · description 超过 1024 字符（921 + 200）" \
  "pad skills/ui-contract/SKILL.md 'description: \"' 200"
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
run_case 1 "22 · 装置文件之外的产品组件写死了品牌色" \
  "sub $W_TPL 'export function Badge({ children }: { children: ReactNode }) {' 'export function Badge({ children }: { children: ReactNode }) {
  const leak = \"#2563eb\"; void leak;'"
run_case 1 "22 · SKIN 出厂就填好了 token 名" \
  "sub $W_TPL \"'--wire-surface': ''\" \"'--wire-surface': 'background'\""
run_case 1 "23 · 模板新增导出，示例与 README 都没提" \
  "printf '\nexport function InjectedThing() { return null }\n' >> $W_TPL"
# 这条断言的锚从「const|function|type 三种拼法」加宽到「行首 export + 声明关键字」之后，
# 必须证明加宽真的生效：换一种拼法写同一个违规，旧锚会安静放行，新锚要照样红。
run_case 1 "23 · 模板新增导出换成 export interface（旧锚只认三种拼法）" \
  "printf '\nexport interface InjectedThing { x: number }\n' >> $W_TPL"

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

# 注入到 theme-studio.html.template——那份模板在干净树上一处开发树引用都没有，
# 所以红只可能来自注入。34 曾短暂是 warn 档（落地当天模板里还有 15 处），清干净后转失败。
run_case 1 "34 · skills/ 里引用了插件自身的开发树" \
  "printf '\n<!-- 详见 ADR-0099 与 testing/structure/invariants.sh -->\n' >> $T"

# 同一个违规换个拼法。目录名后原本是 `[a-z]`，于是这两个路径——两个目录里最可能
# 被引用的文件——一个都不匹配，而 ADR 编号那一支照样红，所以上面那条用例发现不了。
run_case 1 "34 · 同上，引的是 examples/README.md 与 testing/README.md（首字母大写）" \
  "printf '\n<!-- 见 examples/README.md 与 testing/README.md -->\n' >> $T"

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
# 22 的锚 ADR-0012 换过一次：例外从一对注释哨兵变成一个文件。下面四条是**新锚的
# 绕过口**，一一对应旧锚被实测穿透过的那两种（把 END 推到文件尾＝全文豁免；把产品
# 组件搬进块内）。锚变了，攻击面也变了，所以用例必须跟着重写——留着打不中的旧用例
# 比没有用例更糟，它会让「这条守得住」看起来有证据。
#
# 第一种：把产品零件搬进豁免文件，在里面写死颜色。这是旧锚下**一次搬一个就能穿过去**
# 的那条路，现在由「装置文件的导出是封闭名单」挡住。
run_case 1 "22 · 把产品零件搬进装置文件，在里面写死品牌色" \
  "python3 - <<'INJ'
import re
P='skills/ui-contract-wireframe/assets/wire.tsx.template'
A='skills/ui-contract-wireframe/assets/inspect.tsx.template'
s=open(P,encoding='utf-8').read()
m=re.search(r'\nexport function Btn\(\{.*?\n\}\n', s, re.S)
blk=m.group(0).rstrip(chr(10))+chr(10)+\"const BTN_BRAND = '#2563eb'\"+chr(10)
open(P,'w',encoding='utf-8').write(s[:m.start()]+chr(10)+s[m.end():])
open(A,'a',encoding='utf-8').write(chr(10)+blk)
INJ"
# 第二种：不搬产品进来，只在豁免文件里多开一个导出。名单式检查的整个价值就在这里——
# 它不判断什么该进来，只强制这个决定被写下来，而写下来会出现在 diff 里。
run_case 1 "22 · 给装置文件加一个未声明的导出（豁免区不许悄悄变大）" \
  "printf '\nexport function Sneaky() { return null }\n' >> skills/ui-contract-wireframe/assets/inspect.tsx.template"
# 同一处违规，**只换一种拼法**。旧断言把导出名的锚放在 const|function|type 这三个词上，
# 于是这两条一条都打不中：实测过，追加 `export async function Sneaky() { return "#2563eb" }`
# 之后 check-colours.sh 照样印「apparatus exports match the declared list」。
# 名单封的是名字，锚却封在拼法上——这正是本仓库那类「断言存在但打不中」的失效，
# 而且它一次能穿掉 ADR-0012 的整个机制，不是穿掉一个角。
run_case 1 "22 · 未声明的导出换成 export async function（旧锚只认三种拼法）" \
  "printf '\nexport async function Sneaky() { return null }\n' >> skills/ui-contract-wireframe/assets/inspect.tsx.template"
# 另一条拼法，走的是不同的分支（花括号名单而不是「跳修饰词取标识符」），所以要单独证。
run_case 1 "22 · 未声明的导出换成 export { X as Y } 名单形式" \
  "printf '\nconst sneaky = 1\nexport { sneaky as Sneaky }\n' >> skills/ui-contract-wireframe/assets/inspect.tsx.template"
# 名单现在只有一个家，所以要证明那个家真的在被读：把声明行删掉必须红，
# 不能因为「找不到声明」而当成「没有声明任何东西」——那会把整个文件悄悄豁免。
run_case 1 "22 · 把 APPARATUS: 声明行删掉（缺席不是「没声明任何东西」）" \
  "sub skills/ui-contract-wireframe/assets/inspect.tsx.template ' * APPARATUS: ' ' * 装置清单： '"
# 反向：往声明里加一个名字、但文件里没有这个导出，不该红——名单是上界不是等式。
# 少了这条，下一个人会把它改成相等判断，然后每次拆分组件都要同步改声明。
run_case 0 "22 · 声明里多一个尚未存在的名字 → 不判红（名单是上界）" \
  "sub skills/ui-contract-wireframe/assets/inspect.tsx.template 'APPARATUS: LabelsProvider' 'APPARATUS: NotYetWritten LabelsProvider'"
# 第三种，方向相反、也最容易被忽略：把装置**搬出去**。它带着自己的固定色，一出豁免
# 文件那些色就成了裸露的值。旧锚下这等于把代码挪到哨兵块外，是同一件事。
run_case 1 "22 · 把装置搬出装置文件（固定色跟着离开豁免区）" \
  "python3 - <<'INJ'
import re
P='skills/ui-contract-wireframe/assets/wire.tsx.template'
A='skills/ui-contract-wireframe/assets/inspect.tsx.template'
s=open(A,encoding='utf-8').read()
m=re.search(r'export function SkinBanner\(\{.*?\n\}\n', s, re.S)
open(A,'w',encoding='utf-8').write(s[:m.start()]+s[m.end():])
open(P,'a',encoding='utf-8').write(chr(10)+m.group(0))
INJ"
# 第四种：整个删掉豁免文件。例外既然是一个文件，那个文件不在就不是「没有例外」，
# 而是「断言不知道自己在判什么」——必须红，不能静静地判成全绿。
run_case 1 "22 · 删掉装置文件（例外的载体没了，不许当成没有例外）" \
  "rm -f skills/ui-contract-wireframe/assets/inspect.tsx.template"

# 21 与 22 各自的名单/记法缺口：违规原封不动，只换一种写法。
# 两条都是「名单式检查」的通病——名单永远差一个，所以补的时候连同**没补的**
# 一起写进断言注释里，让下一个人看得见边界在哪，而不是以为它守住了全部。
run_case 1 "21 · 用 <aside> 代替 <nav>（名单外的 IA 载体）" \
  "sub $T '<body' '<body><aside class=\"panel\">nav</aside'"
run_case 1 "22 · 用 CSS 具名颜色写死值（记法外的颜色）" \
  "sub $W_TPL 'export function Badge({ children }: { children: ReactNode }) {' 'export function Badge({ children }: { children: ReactNode }) {
  const leak = { color: \"crimson\" }; void leak;'"

echo "C2. 36 · frontmatter 能被严格 YAML 解析"
# 第一条是真实发生过的那一种：没加引号的 description 里出现 `: `。
# 3 与 8 跳过解析不了的文件，所以只有 36 红。
run_case 1 "36 · 未加引号的 description 里有 \`: \`（0.3.1–0.3.2 真实带出去的病）" \
  "sub skills/ui-contract-glossary/SKILL.md 'description: ' 'description: Chinese: '"
# 换一种写法：不是冒号，是以反引号开头——YAML 的保留字符，写 \`layout.md\` 开头的
# 描述很自然。只防冒号的检查在这里会绿，真解析器不会。
run_case 1 "36 · description 以反引号开头（保留字符，另一种解析失败）" \
  "sub skills/ui-contract-glossary/SKILL.md 'description: ' 'description: \`x\` '"
# 反方向：加了引号的值里有 \`: \` 必须是绿的。判的是「解析得了」，不是「出现了冒号」。
run_case 0 "36 · 加了引号的 description 里有 \`: \` → 不判红" \
  "sub skills/ui-contract-design/SKILL.md 'description: \"' 'description: \"Note: '"

echo "D. 32 · 覆盖承诺与检查数"
# 这条断言守的是**这份文件自己**，所以它的用例也在这份文件里——递归但没问题：
# 注入发生在临时副本里，跑的是那份副本的 invariants.sh 读那份副本的 effectiveness。
run_case 1 "32 · 加一条检查但不加用例（CLAUDE.md 说这不算完成）" \
  "printf '\necho \"99. 新检查\"\nok \"x\"\n' >> testing/structure/invariants.sh"
# 锚必须带上行首的 `# 覆盖范围` 前缀。不带的话，`sub` 在副本里**先命中用例自己这一行**
# ——参数里含着同一串字——于是注入「成功」了却没碰承诺行，副本干净、退出 0。
# 第 32 条的检查早就为此把锚钉在行首注释上；用例这一侧漏了，2026-08-26 补上。
run_case 1 "32 · 覆盖承诺的上界与实际条数对不上（那一行变回散文）" \
  "sub testing/structure/invariants-effectiveness.sh '# 覆盖范围（这一行是承诺，别让它变成散文）：**1–36 全部有用例**' '# 覆盖范围（这一行是承诺，别让它变成散文）：**1–99 全部有用例**'"
run_case 1 "32 · 覆盖承诺整句被删掉（唯一的全称声明不许消失）" \
  "sub testing/structure/invariants-effectiveness.sh '# 覆盖范围（这一行是承诺，别让它变成散文）：**1–36 全部有用例**' '覆盖了一些检查'"

echo "E. 33 · 颜色知识三份一致"
# 漂移的三种走法各一条：改一份、把哨兵删掉、把名单裁短。
run_case 1 "33 · 只改了 audit.sh 那一份的记法（三向漂移的起点）" \
  "sub skills/ui-contract-audit/assets/audit.sh.template 'oklab' 'oklabX'"
run_case 1 "33 · 只改了线框那一份的具名名单" \
  "sub skills/ui-contract-wireframe/assets/check-colours.sh.template '|crimson|' '|'"
# 哨兵没了就无从比对——那必须红，不能因为「找不到就当通过」而静默。
run_case 1 "33 · 某一份的 COLOUR_NOTATION 哨兵被删掉" \
  "sub skills/ui-contract-audit/assets/audit.sh.template 'COLOUR_NOTATION=' 'COLOUR_NOTATION_OLD='"

# 35 · 示例的 check-colours.sh 与模板同源。这条检查是买来的：示例那份当时停在
# 被证伪的旧实现上（检查 2 枚举三种拼法），对 `export async function` 打印通过。
# 两个方向都要钉——只钉红的一半，一条恒红的检查也能拿满分。
run_case 1 "35 · 只改了示例那一份的实现（分家的起点，真实发生过）" \
  "python3 -c \"import io;p='examples/admin-console/check-colours.sh';s=io.open(p,encoding='utf-8').read();io.open(p,'w',encoding='utf-8').write(s.replace('every NEUTRAL role has a SKIN decision','all roles mapped',1))\""
# 换个方向：动模板而不动示例。上一条改的是示例，这一条改的是模板——比对是对称的，
# 但「谁被改了」在真实场景里不对称：模板改了而示例没跟，正是这次实际发生的那个方向。
run_case 1 "35 · 只改了模板那一份（模板前进、示例留在原地，就是这次的方向）" \
  "python3 -c \"import io;p='skills/ui-contract-wireframe/assets/check-colours.sh.template';s=io.open(p,encoding='utf-8').read();io.open(p,'w',encoding='utf-8').write(s.replace('every NEUTRAL role has a SKIN decision','all roles mapped',1))\""
# 路径赋值行是**声明过的**豁免：模板的 TODO 就是让人改它们的。改了不许判红，
# 否则这条检查会拦住每一个把工作台配到别处的项目——CLAUDE.md 记的第二类事故。
run_case 0 "35 · 示例调整了路径赋值行 → 不判红（那三行是声明过的豁免）" \
  "python3 -c \"import io;p='examples/admin-console/check-colours.sh';s=io.open(p,encoding='utf-8').read();io.open(p,'w',encoding='utf-8').write(s.replace('WIRE_SRC=\\\".ui-contract-local/wireframe/src\\\"','WIRE_SRC=\\\".workbench/wire/src\\\"',1))\""

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
