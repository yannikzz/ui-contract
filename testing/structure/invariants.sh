#!/bin/sh
# 结构不变量。不花钱、不需要 agent、秒级完成。
#
# 单一来源是**磁盘**：skills/ 下每个含 SKILL.md 的目录就是一个包。
# 两份 manifest 与 README 索引都只是它的投影，由第 1 项对账。
# 这些不变量一旦破掉，插件会装不全、组合链会断、或索引会说谎。
cd "$(dirname "$0")/../.." || exit 1
FAIL=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$1"; }

echo "1. 磁盘 / plugin.json / marketplace.json / README 索引 四处一致"
python3 - <<'PY' || FAIL=1
import json,os,re,sys
dirs=sorted(d for d in os.listdir('skills') if os.path.exists(f'skills/{d}/SKILL.md'))
pj=sorted(p.split('/')[-1] for p in json.load(open('.claude-plugin/plugin.json'))['skills'])
mk=sorted(p.split('/')[-1] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['skills'])
rd=sorted(set(re.findall(r'\]\(skills/([a-z-]+)/SKILL\.md\)', open('README.md').read())))
bad=0
for name,got in (('plugin.json',pj),('marketplace.json',mk),('README 索引',rd)):
    if got!=dirs:
        print(f'  \033[31m✗\033[0m {name} 与磁盘不一致: {sorted(set(dirs)^set(got))}'); bad=1
    else: print(f'  \033[32m✓\033[0m {name} ({len(got)} 个)')
sys.exit(bad)
PY

echo "2. frontmatter name 与目录名一致"
M=""; for d in skills/*/; do n=$(grep -m1 '^name:' "$d/SKILL.md" | sed 's/name: *//'); b=$(basename "$d"); [ "$n" = "$b" ] || M="$M $b"; done
[ -z "$M" ] && ok "全部一致" || no "不一致:$M"

echo "3. description 在 1024 字符 / 1022 UTF-8 字节内"
python3 - <<'PY' || FAIL=1
import re,os,sys
bad=0;tot=0
for d in sorted(os.listdir('skills')):
    p=f'skills/{d}/SKILL.md'
    if not os.path.exists(p): continue
    fm=open(p).read().split('---')[1]
    m=re.search(r'^description:\s*(.*?)(?=\n[a-z_-]+:\s|\Z)', fm, re.S|re.M)
    s=m.group(1).strip() if m else ''
    n=len(s); b=len(s.encode()); tot+=n
    if n>1024 or b>1022: print(f'  \033[31m✗\033[0m {d}: {n} 字符 / {b} 字节'); bad=1
    elif n==0: print(f'  \033[31m✗\033[0m {d}: 无 description'); bad=1
print(f'  \033[32m✓\033[0m 全部合规，常驻合计 {tot} 字符')
sys.exit(bad)
PY

echo "4. 全部 model-invoked（user-invoked 的技能任何别的技能都调不到，组合链会断）"
H=$(grep -rl 'disable-model-invocation' skills/ 2>/dev/null)
[ -z "$H" ] && ok "无 disable-model-invocation" || no "以下技能不可被组合调用: $H"

echo "5. 原语层不含 UI 词汇（否则无法被别的项目复用，且会和能力层抢触发）"
# 锚是**一张词表**，所以按 CLAUDE.md 的规矩要说清它放过什么。
# 名单：layout.md / design.md / wireframe / region / allowlist / 界面 / UI contract / 区域。
# **走得过去的**：`token`、`spec`、`contract`（不带 UI）、`skin`、`纪律`、`产物`——
# 它们在原语层是通用词，加进名单会当场误报（`decision-record` 通篇讲 authoritative
# document，`deliverable-language` 讲 deliverable）。
# 也走得过去的是**换个说法**：「区域名白名单」写成 "the allow-list of names" 就漏了。
# 这条挡的是**照抄**，不是挡决心——真要往原语层塞 UI 概念的人，改个词就过。
for s in decision-interview spec-before-code constraint-by-types decision-record deliverable-language; do
  [ -f "skills/$s/SKILL.md" ] || { no "$s 缺失"; continue; }
  h=$(grep -oiE 'layout\.md|design\.md|wireframe|region|allowlist|界面|UI contract|区域' "skills/$s/SKILL.md" | sort -u | tr '\n' ' ')
  [ -z "$h" ] && ok "$s" || no "$s 出现 UI 词汇: $h"
done

echo "6. 无跨包相对路径引用（装完后各包是孤立目录，跨包路径必失效）"
X=$(grep -rn '](\.\./' skills/ 2>/dev/null)
[ -z "$X" ] && ok "无 ../ 跨包引用" || no "$X"

echo "7. 包内 markdown 链接不断"
# **走得过去的**：正则是 `\]\(([^)#:]+)\)`，所以带 `#` 锚点的链接
# （`[x](implementation.md#section)`）和带 `:` 的（外部 URL）**整条被跳过**，不是只跳锚点。
# 也就是说 `[x](nonexistent.md#foo)` 是绿的。这是刻意的：跳过 URL 必须的，而为了
# 跳 URL 用的字符类顺带把锚点也吃了。修它要拆成两步匹配，收益是抓到带锚点的死链——
# 目前包内一处带锚点的链接都没有，所以这个洞现在是空的，写在这里是防它以后不空。
python3 - <<'PY' || FAIL=1
import re,os,sys
bad=0
for root,_,files in os.walk('skills'):
    for f in files:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for link in re.findall(r'\]\(([^)#:]+)\)', open(p).read()):
            t=os.path.normpath(os.path.join(root,link))
            if not os.path.exists(t):
                print(f'  \033[31m✗\033[0m {p} → {link}'); bad=1
if not bad: print('  \033[32m✓\033[0m 全部可达')
sys.exit(bad)
PY

echo "8. 只有编排层与 audit 配富触发词（其余 description 只覆盖自己那件产物）"
python3 - <<'PY' || FAIL=1
import re,os,sys
RICH={'ui-contract','ui-contract-audit'}
bad=0
for d in sorted(os.listdir('skills')):
    p=f'skills/{d}/SKILL.md'
    if not os.path.exists(p): continue
    fm=open(p).read().split('---')[1]
    m=re.search(r'^description:\s*(.*?)(?=\n[a-z_-]+:\s|\Z)', fm, re.S|re.M)
    n=len(m.group(1).strip()) if m else 0
    if d in RICH and n<400: print(f'  \033[31m✗\033[0m {d} 是入口却只有 {n} 字符，触发面不够'); bad=1
    if d not in RICH and n>600: print(f'  \033[31m✗\033[0m {d} 不是入口却有 {n} 字符，会和入口抢触发'); bad=1
if not bad: print('  \033[32m✓\033[0m 富/窄 description 分工正确')
sys.exit(bad)
PY

echo "9. 凡有提问的单元都接上了访谈纪律（漏这条时行为看着完全正常，只能靠断言守）"
for s in ui-contract-setup ui-contract-baseline ui-contract-layout ui-contract-design ui-contract-wireframe ui-contract-enforce; do
  grep -qi 'call the Skill tool with "decision-interview"' "skills/$s/SKILL.md" 2>/dev/null \
    && ok "$s" || no "$s 未调用 decision-interview"
done

echo "10. 每个能力包都有前置门（缺上游产物 → 停；这是拆包后「不许倒序」的唯一载体）"
for s in ui-contract-layout ui-contract-design ui-contract-assets ui-contract-wireframe ui-contract-enforce ui-contract-audit; do
  grep -q '^## Preconditions' "skills/$s/SKILL.md" 2>/dev/null \
    && ok "$s" || no "$s 无 ## Preconditions 段"
done

echo "11. 凡产出文字的包都接上了语言纪律"
for s in ui-contract-setup ui-contract-baseline ui-contract-layout ui-contract-design ui-contract-wireframe ui-contract-enforce ui-contract-audit; do
  grep -qi 'call the Skill tool with "deliverable-language"' "skills/$s/SKILL.md" 2>/dev/null \
    && ok "$s" || no "$s 未调用 deliverable-language"
done

echo "12. 技能包内不含测试 / eval / examples（install.sh 整目录拷贝，会发给每个用户）"
X=$(find skills -path '*/testing/*' -o -path '*/tests/*' -o -path '*/evals/*' -o -path '*/examples/*' 2>/dev/null)
[ -z "$X" ] && ok "技能包只含运行时资产" || no "$X"

echo "14. 能力包与事实包都从 config 读产物落点（落点一漂，入口/前置门/体检脚本同时失效）"
for s in ui-contract-baseline ui-contract-layout ui-contract-design ui-contract-assets ui-contract-wireframe ui-contract-enforce ui-contract-audit; do
  grep -q "paths table" "skills/$s/SKILL.md" 2>/dev/null && ok "$s" || no "$s 未声明从 config 读落点"
done

echo "15. 决策树的追踪要求落进产物，不只要求「做过」（issue #5：做没做在输出里看不出来）"
grep -q '^## Appendix C' skills/ui-contract-layout/layout-md-outline.md \
  && ok "大纲有 Appendix C（追踪表的落点）" || no "layout-md-outline.md 无 Appendix C，追踪结果没有产物落点"
N=$(grep -c 'Appendix C' skills/ui-contract-layout/SKILL.md)
[ "$N" -ge 2 ] && ok "完工清单的两条追踪都指向落点" \
                || no "ui-contract-layout 完工清单只有 $N 处提到 Appendix C（敌意/普通两条都要指）"

echo "16. 体检技能讲清了 exit 2 与 exit 3 的分别（脚本拦得住，技能不讲的话 agent 照样会说那句话）"
python3 - <<'P16' || FAIL=1
import re,sys
s=open('skills/ui-contract-audit/SKILL.md',encoding='utf-8').read()
bad=0
if re.search(r'^\| 3 \|', s, re.M): print('  \033[32m✓\033[0m 退出码表里有 exit 3')
else:
    print('  \033[31m✗\033[0m SKILL.md 没有 exit 3 这一行——技能不讲，脚本的分辨就只活在产物里'); bad=1
row=re.search(r'^\| No `layout\.md`[^\n]*\|', s, re.M)
if row and 'config' in row.group(0): print('  \033[32m✓\033[0m 前置门第一行按 config.md 是否存在分了叉')
else:
    print('  \033[31m✗\033[0m 前置门第一行没有区分「有没有 config.md」，会教 agent 说出 exit 3 要拦的那句话'); bad=1
sys.exit(bad)
P16

echo "17. 同一条判据的每一份拷贝仍然一致（手抄的第二份迟早要说谎）"
# 判据住在三种地方：evals/*/graders/*.md、evals/*/case.yaml 的内联、以及 grader-check/
# 夹具里的内联。夹具的全部价值在于「验的是线上那一条」，抄歪了比没有夹具更坏。
# 口径：忽略空白与 **，并剥掉 markdown grader 的标题行——case.yaml 内联的那份不含标题，
# 这个差异是被容忍的（judge 实际收到的文本因此有细微不同，但没有证据表明它有影响）。
python3 - <<'P17' || FAIL=1
import re,sys,glob
def norm(s): return re.sub(r'\s+','',s.replace('**',''))

def defs_in_yaml(text, where):
    out=[]
    for blk in re.split(r'\n  - type: ', text)[1:]:
        n=re.search(r'name: ([\w-]+)', blk)
        if not n: continue
        mp=re.search(r'pattern: "([^"]*)"', blk)
        if mp: out.append((n.group(1),'pattern',mp.group(1),where)); continue
        mc=re.search(r'criteria: \|\n((?:      [^\n]*\n|\n)*)', blk)
        if mc: out.append((n.group(1),'criteria',mc.group(1),where))
    return out

found=[]
for f in sorted(glob.glob('testing/evals/*/graders/*.md')):
    src=open(f,encoding='utf-8').read()
    name=f.split('/')[-1][:-3]
    fm=src.split('---')[1]
    mp=re.search(r'^pattern: "([^"]*)"', fm, re.M)
    if mp: found.append((name,'pattern',mp.group(1),f))
    else:
        body=re.sub(r'^#[^\n]*\n','',src.split('---',2)[2].lstrip('\n'))
        found.append((name,'criteria',body,f))
for f in sorted(glob.glob('testing/evals/*/case.yaml'))+sorted(glob.glob('testing/grader-check/*/case.yaml')):
    found+=defs_in_yaml(open(f,encoding='utf-8').read(), f)

by={}
for name,kind,val,where in found: by.setdefault((name,kind),[]).append((val,where))
bad=0; checked=0
for (name,kind),vals in sorted(by.items()):
    if len(vals)<2: continue
    checked+=1
    base,bw=vals[0]
    for val,w in vals[1:]:
        same = (val==base) if kind=='pattern' else (norm(val)==norm(base))
        if not same:
            print(f'  \033[31m✗\033[0m {name} 的 {kind} 已经分家: {bw} vs {w}'); bad=1
if bad: sys.exit(1)
print(f'  \033[32m✓\033[0m {checked} 条有多份拷贝的判据仍然一致')
P17

echo "18. 体检模板里没有「行式匹配整个标签」的检查（同一个坑踩过两次，且两次输出都正常）"
# 模板自己在文件头写着：凡是看调用点的检查都必须一次看见整个标签，因为属性一多
# prettier 就换行。检查 2b 违反了这条，绿着漏了很久——注释拦不住第三次，这条能。
# 判据：带 -r 的 grep（逐文件行式扫描）不许带 `<`（标签模式）。要匹配标签就走
# flatten_sources。不带 `<` 的 -r grep 是找裸标识符，不受这条约束。
X=$(grep -n 'grep -r' skills/ui-contract-audit/assets/audit.sh.template | grep '<')
[ -z "$X" ] && ok "看调用点的检查都走 flatten_sources" || no "行式匹配标签，调用点一换行就全瞎: $X"
echo "19. design 单元写死了 tokens.input.json 的身份（不写死它就是第二个值权威）"
# 与检查 18 同源：同一类失效在这个仓库发生过两次，两次输出都完全正常。
# 一份「用户拧到哪」的输入记录和一份「当前正确的值」的权威，磁盘上长得一样，
# 谁说了算只活在文本里——所以那句话必须在，且必须是断言守着，不是注释守着。
# 判的是**身份表那两行**，不是三个词在全文任意位置各出现一次：`value authority`
# 在这份文件里本来就为 token 文件出现过好几次，散着数词的写法三个条件都能被
# 不相关的正文满足——那样这条断言就成了它自己要防的那种「看着像在检查」的检查。
#
# 第二版仍然不够：它只要求「某一行同时含两组词」，而一句随口的散文就能满足
# （量过：把整张表删掉、末尾补一句 "tokens.input.json is an input record. The
# token file holds values that are currently correct." ——断言照样绿）。所以锚点
# 现在钉在**表格结构**上：必须是以 `|` 开头的表行，且必须带上冲突判定那一列。
# 「谁说了算」正是靠那一列表达的，一句散文说不出 does not count / wins。
D="skills/ui-contract-design/SKILL.md"
R1=$(grep -cE '^\| *`tokens\.input\.json` *\|.*input record.*\| *does not count *\|' "$D")
R2=$(grep -cE '^\| *the token file *\|.*currently correct.*\| *wins *\|' "$D")
if [ "$R1" -ge 1 ] && [ "$R2" -ge 1 ]; then
  ok "design/SKILL.md 有身份表：JSON 是输入记录、token 文件是当前正确的值"
else
  no "design/SKILL.md 的 tokens.input.json 身份表不完整（输入记录 $R1 行 / 值权威 $R2 行）"
fi

echo "20. 器具模板内没有内置 token 名清单（内置 = 替项目决定命名 = 第二套词汇）"
# 名单住在 design-md-outline.md（起草底稿），权威住在 design.md 的声明表。
# 器具**必须**从 design.md 反推。名单一旦存在，把它复制进器具的诱惑才真正出现,
# 所以这条断言是在名单落地之后变得更重要，不是更不重要。
# 判据是 ROLE 映射表的值必须全空：键是通用角色（sample 要知道哪个 token 画哪一块），
# 值是项目自己的 token 名，由 agent 从声明表填。填好的模板不该进仓库。
python3 - <<'P20' || FAIL=1
import re,sys
p='skills/ui-contract-design/assets/theme-studio.html.template'
try: s=open(p,encoding='utf-8').read()
except OSError: print('  \033[31m✗\033[0m 找不到 '+p); sys.exit(1)
m=re.search(r'const ROLE\s*=\s*\{(.*?)\n\}', s, re.S)
if not m:
    print('  \033[31m✗\033[0m 模板里找不到 ROLE 映射表——它是「无内置名单」这件事的载体'); sys.exit(1)
filled=[v for v in re.findall(r":\s*'([^']*)'", m.group(1)) if v.strip()]
if filled:
    print(f'  \033[31m✗\033[0m ROLE 里填了 token 名: {filled}——这就是内置名单'); sys.exit(1)
print('  \033[32m✓\033[0m ROLE 全空，器具不带名单')
P20

echo "21. 器具模板里不出现 IA 载体（放了它就是向每个装了插件的项目发一份信息架构）"
# 严格到「连提都不能提」，与 eval 的 no-desktop-skeleton 同一条理由：
# 无论是在采纳还是在否定它，出现即说明参照系是别人的产品。要说明排除了哪些，
# 写在 originate.md 里——那份文件不受这条断言约束，因为它不是发给项目的产物。
# 名单式检查天生不全，所以名单里有什么、为什么少了什么，都得写下来。
# 量过：第一版只有五个词，`<aside>` 一个标签就走过去了——而侧栏正是这条断言
# 点名要挡的形状。补齐同类的 IA 区域词之后，仍有四个词**刻意没进名单**：
#   · `shell`  —— 器具自己的两栏布局 class 就叫 `.shell`，加了当场假阳
#   · `menu` / `banner` —— 下拉菜单、状态提示条都是通用控件，不是 IA 载体
#   · `toolbar` —— 页面级工具栏是 IA，卡片内的操作条不是，一个词分不开这两件事
#   · `<main`  —— 它是无障碍 landmark，不传递「导航长什么样」，加了只会逼器具
#                 放弃语义标签，换来的不是更少的信息架构
# 假阳比漏判贵：一条会误报的断言，第一次误报就会被加例外，例外一多就没人看了。
X=$(grep -niE '<nav|<aside|sidebar|crumb|<header|<footer|drawer|topbar|tabbar|masthead|navigation|appbar' skills/ui-contract-design/assets/theme-studio.html.template 2>/dev/null)
[ -z "$X" ] && ok "样张只有通用控件" || no "模板里有 IA 载体: $X"

echo "22. 线框模板里颜色的**值**只在 NEUTRAL 与装置文件（ADR-0006 换判据，ADR-0012 换锚）"
# 一条被推翻的决定需要机械守卫，不是一句叮嘱。ADR-0001 当初禁掉换肤预览，靠的是
# 「线框里没有颜色」——那条好守，也挡住了用户真正要看的东西。换成「没有颜色的值」
# 之后线框可以换肤而依然不可能成为第二个视觉真相源，但**只有这条断言在时才成立**。
#
# **锚变了。** 到 ADR-0012 为止，例外由 `wire.tsx.template` 里一对 `INSPECT CHROME`
# 注释哨兵声明，而注释可以挪：把 END 推到文件尾就是全文豁免，把产品组件整段搬进块内
# 就能在里面写死颜色。两条都是实测穿透，两次都靠往断言里补一层来堵。现在例外是**一个
# 文件**：`inspect.tsx.template`。搬进豁免区因此是一次文件移动，在 diff 里看得见，
# 而挪两行注释在 review 里长得像格式调整。
#
# **这条抓不到的**：往 NEUTRAL 里直接加一个品牌色。NEUTRAL 内允许写值——那是线框
# 自己的灰——所以「加进去的是不是灰」只能靠人评审。量过：注入 `'--wire-brand':
# '#2563eb'` 仍然 exit 0。不写下来的话，下一个读这条断言的人会以为它守住了整件事。
python3 - <<'P22' || FAIL=1
import re,sys
PARTS='skills/ui-contract-wireframe/assets/wire.tsx.template'
APP='skills/ui-contract-wireframe/assets/inspect.tsx.template'
try:
    parts=open(PARTS,encoding='utf-8').read()
    app=open(APP,encoding='utf-8').read()
except OSError as e:
    print(f'  \033[31m✗\033[0m 读不到 {e.filename}——例外是一个文件，那个文件必须存在'); sys.exit(1)
bad=0
m=re.search(r'export const NEUTRAL[^{]*\{(.*?)\n\}', parts, re.S)
if not m:
    print('  \033[31m✗\033[0m 模板里找不到 NEUTRAL——它是「值只在一处」的载体'); sys.exit(1)
rest = parts[:m.start()] + parts[m.end():]
# 豁免文件的导出是**声明出来的**封闭名单。产品组件搬进去就买到了写死颜色的权利，
# 所以多一个名字必须改这张名单，而改名单会出现在 diff 里。这一条不替作者判断什么
# 该进来，只强制这个决定被写下来。名单同时被随线框交付的 check-colours.sh 使用。
# 名单**读自装置文件自己的 `APPARATUS:` 行**，这里不留拷贝。
# 决定住在做决定的地方：往豁免文件里加一个名字，diff 里就挨着那个名字本身。
# 以前是一个决定三份拷贝，加一次要改三处，而检查是唯一会发现漏改的东西。
m_decl = re.search(r'APPARATUS:\s*(.+)', app)
if not m_decl:
    print('  \033[31m✗\033[0m 装置模板里没有 APPARATUS: 行——封闭名单声明在那里、也从那里读；'
          '注释被翻译时这个标记必须保持 ASCII'); sys.exit(1)
APPARATUS_EXPORTS = set(m_decl.group(1).split())
# ── 这一段锚在什么上 ──────────────────────────────────────────────────────
# 锚是**句法位置**：行首的 `export`。不是它后面那串关键字。
# 旧写法枚举了 const|function|type 三种拼法——对一条「名字是封闭名单」的检查来说，
# 这是正好搞反了的锚：名单封的是名字，而它把**拼法**当成了封闭集。量过：把
# `export async function Sneaky() { return "#2563eb" }` 追加进装置文件，检查照样绿。
# `export default` / `export interface` / `export enum` / `export let` / `export var` /
# `export { X }` 同样从中间走过去，于是 ADR-0012 那份封闭名单换个拼法就等于不存在。
#
# 现在的规则：跳过所有修饰词，取后面第一个标识符；`export { A, B as C }` 读成它对外
# 发布的名字（A、C）；`export default …` 报成名字 `default`，`export * …` 报成 `*`——
# 两者都永远不在声明名单里，所以都会被判成未声明，而那正是「名单点不到名的导出」
# 应得的判决。
#
# **仍然穿得过去的，写下来而不是暗示**：
#   · 跨行写的导出（`export {` 名字在下几行；名字与 `export` 不在同一行）。这里逐行读，
#     和 check-colours.sh 一致。
#   · `export * from './x'` 会红，但它说不出**进来了哪些名字**。
#   · `export const [a] = …` 这种数组解构，取不到名字。
#   · TypeScript 的 `export =`，它没有名字可判。
MODIFIERS = ('async','declare','abstract','const','let','var','function','class','type','interface','enum')
def exported_names(src):
    names = set()
    for line in re.findall(r'^export[ \t][^\n]*', src, re.M):
        if re.match(r'^export[ \t]+\*', line):
            names.add('*'); continue
        if re.match(r'^export[ \t]+(?:type[ \t]+)?\{', line):
            m_br = re.search(r'\{([^}]*)\}', line)
            if m_br:
                for part in m_br.group(1).split(','):
                    w = part.split()
                    if w: names.add(w[-1])          # `A as C` 对外是 C
            continue
        for tok in line.split()[1:]:
            tok = re.sub(r'[^A-Za-z0-9_$].*$', '', tok)   # `Foo({` → `Foo`；`function*` → `function`
            if not tok: continue
            if tok == 'default': names.add('default'); break
            if tok in MODIFIERS: continue
            names.add(tok); break
    return names
inside = exported_names(app)
extra = sorted(inside - APPARATUS_EXPORTS)
if extra:
    print(f'  \033[31m✗\033[0m 装置文件里出现了未声明的导出: {extra}——产品组件搬进豁免文件就能随便写颜色；'
          f'确实属于装置的话，把名字加进装置文件自己的 APPARATUS: 行——名单只有那一份，这里和 check-colours.sh 都读它'); sys.exit(1)
# 反向也要判：豁免文件被掏空、产品组件全搬去别处，等于豁免了个寂寞——但真正的风险
# 是**产品零件搬进了装置文件**（上面那条），以及**装置搬出去写死颜色**（下面这条会抓）。
if not re.search(r'^export function', rest, re.M):
    print('  \033[31m✗\033[0m 零件文件里已经没有产品组件了——产品表面若整体搬进豁免文件，上面那条名单是唯一防线'); sys.exit(1)
COLOUR_NOTATION=r'#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(|\boklch\(|\boklab\(|\blab\(|\blch\(|\bcolor\(|\b(bg|text|border|ring|fill|stroke|outline|divide|from|via|to)-(red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|slate|gray|grey|zinc|neutral|stone)-[0-9]{2,3}\b'
COLOUR_NAMED=r'aqua|beige|black|blue|brown|chartreuse|chocolate|coral|crimson|cyan|darkblue|darkgreen|darkred|deeppink|dodgerblue|firebrick|forestgreen|fuchsia|gold|goldenrod|gray|green|grey|hotpink|indigo|ivory|khaki|lavender|lime|magenta|maroon|navy|olive|orange|orangered|orchid|pink|plum|purple|rebeccapurple|red|salmon|seagreen|sienna|silver|skyblue|steelblue|tan|teal|tomato|turquoise|violet|wheat|white|yellow'
# `finditer` + `group(0)`，不是 `findall`：这个模式带两个捕获组（Tailwind 前缀与色名），
# 于是 findall 返回的是元组，`m[0]` 对每个 hex / 函数写法都是 `''`、对 Tailwind 是 `'bg'`。
# 判定一直是对的（该红时红），坏掉的是诊断——它印出来的是 `['']`，而不是漏出来的那个值。
# 模式本身一个字都不能动：第 33 条要求这串 ERE 在三个文件里逐字相同，把组改成非捕获
# 就是把「同一份知识三处相同」换成「三处不同但语义相同」，那正是第 33 条要治的病。
leaks = [m.group(0) for m in re.finditer(COLOUR_NOTATION, rest)]
# 上面那条只认记法（hex / 函数 / tailwind 色阶），于是 `color: 'crimson'` 从中间穿
# 过去——同样是一个写死在线框里的颜色值，只是用词写的。量过：注入 crimson 仍 exit 0。
# 具名颜色不能光靠词形抓（`whitespace` 里有 white，变量名里什么都有），所以判的是
# **语境**：出现在颜色属性的值位置上，且那个词确实是 CSS 具名颜色。
NAMED = set(COLOUR_NAMED.split('|'))
for w in re.findall(r'(?:^|[^A-Za-z-])(?:[A-Za-z]*[Cc]olor|background|fill|stroke|outline|boxShadow|textShadow)\s*:\s*[\'"]?([A-Za-z]{3,20})\b', rest, re.M):
    if w.lower() in NAMED: leaks.append(w)
if leaks:
    print(f'  \033[31m✗\033[0m NEUTRAL 与装置文件之外出现颜色值: {sorted(set(leaks))[:8]}'); bad=1
skin=re.search(r'export const SKIN[^{]*\{(.*?)\n\}', parts, re.S)
if not skin:
    print('  \033[31m✗\033[0m 模板里找不到 SKIN 映射表'); bad=1
else:
    filled=[v for v in re.findall(r":\s*'([^']*)'", skin.group(1)) if v.strip()]
    if filled:
        print(f'  \033[31m✗\033[0m SKIN 里填了 token 名: {filled}——design.md 才是名字权威'); bad=1
if not bad: print('  \033[32m✓\033[0m 颜色值只在 NEUTRAL 与装置文件，SKIN 出厂全空')
sys.exit(bad)
P22

echo "23. 示例要么跟上技能，要么在 README 里写明落后了（examples/README.md 第一句自称是真实产出）"
# 这条是被一次真实的漏网催生的：改了 wire.tsx.template，示例没跟，
# 而 examples/README.md 第一句「Real output from this skill」当场变成假话，
# 全程没有任何东西响。README 的第一句是个会随时间自己变假的断言。
#
# **不强制同步。** 示例是实跑产出，手改它就把「真实产出」变成「手写插图」，
# 毁掉它唯一的价值主张。强制的只是「落后必须是显式的」。
# 方向是单向的：示例自己加的东西（Field / PageKind / TableColumn…）是项目适配，不判。
#
# **模板从一个文件变成两个之后，这里必须读两个。** ADR-0012 把装置拆进
# `inspect.tsx.template`，而这条断言当时只读 `wire.tsx.template`——落后数当场从 7 掉到
# 4，看起来像示例追上了一截，其实是**搬走的那批符号不再被比对**。断言的覆盖面缩小
# 时它不会变红，只会安静地少判，这正是本文件抓的那类失效发生在断言自己身上。
python3 - <<'P23' || FAIL=1
import re,sys
T=['skills/ui-contract-wireframe/assets/wire.tsx.template',
   'skills/ui-contract-wireframe/assets/inspect.tsx.template']
# 示例这一侧也是两个文件了（2026-08-25 重建）。只读 wire.tsx 的话，示例里明明有的
# AnnotatedRegion / DemoBar 等会被算成「落后」，README 得为已经存在的东西写声明——
# 一张记着假落后的表，和一张漏记真落后的表一样没用。
E=['examples/admin-console/.ui-contract-local/wireframe/src/wire.tsx',
   'examples/admin-console/.ui-contract-local/wireframe/src/inspect.tsx']
R='examples/README.md'
# ── 这一段锚在什么上 ──────────────────────────────────────────────────────
# 锚是**行首的 `export` 加一个声明关键字**，不是 const|function|type 这三种拼法。
# 旧写法枚举三种拼法，和 check 22 犯的是同一个错：模板改用 `export interface` /
# `export enum` / `export async function` 写一个新符号，示例没跟，这条**不会变红，
# 只会安静地少判**——落后数从 7 掉到 4 那次就是覆盖面缩小而没人发现。
# 量过：加宽前后模板 23 个、示例 26 个、落后 0 个，一个数都没动，
# 所以这是纯粹的覆盖面加宽，不是判定口径的改动。
#
# **仍然穿得过去的，写下来而不是暗示**：
#   · `export { A, B as C }` 名单式再导出（示例的 wire.tsx 就有一行，只影响 e 这一侧，
#     而这条只判 t - e，漏读 e 只会让落后数偏大、不会漏判）。
#   · `export default`（没有名字可比）、`export * from`（说不出进来了哪些名字）。
#   · 跨行写的声明。这里和 check 22、check-colours.sh 一样逐行读。
def exports(p):
    return set(re.findall(r'^export[ \t]+(?:async[ \t]+|declare[ \t]+|abstract[ \t]+)*'
                          r'(?:const|let|var|function\*?|class|type|interface|enum)[ \t]+'
                          r'([A-Za-z_$][A-Za-z0-9_$]*)',
                          open(p,encoding='utf-8').read(), re.M))
try:
    t = set().union(*(exports(x) for x in T))
    e = set().union(*(exports(x) for x in E))
    rd = open(R,encoding='utf-8').read()
except OSError as err:
    print(f'  \033[31m✗\033[0m 读不到 {err.filename}'); sys.exit(1)
missing = sorted(n for n in t - e if f'`{n}`' not in rd)
if missing:
    print(f'  \033[31m✗\033[0m 模板导出了这些、示例没有、README 也没写明: {missing}'); sys.exit(1)
lag = sorted(t - e)
print(f'  \033[32m✓\033[0m 示例落后 {len(lag)} 个符号，全部在 README 里点了名'
      if lag else '  \033[32m✓\033[0m 示例与模板的导出一致')
P23

echo "24. manifest 的 eval 目录与磁盘一致，且其下每个 case 都是真 case"
# 网关 1（testing/preflight.sh）看不见这件事：`--max-cost-usd 0` 的 JSON 文档里
# `cases: []`（量过），所以「有哪些 case 被发现了」在那一层是不可见的。
# 目录写错时网关 1 会喊「一个 case 都没发现」，但**少了一个 case** 它一声不响。
# 这一条判磁盘：manifest 指的目录要存在，其下每个非 results 的一级目录都要是真 case。
python3 - <<'P24' || FAIL=1
import json,os,sys
d=json.load(open('.claude-plugin/plugin.json',encoding='utf-8'))
ed=(d.get('experimental') or {}).get('evals')
if not ed:
    print('  \033[31m✗\033[0m plugin.json 没有 experimental.evals——eval 目录只能靠每次带 --eval-dir，迟早有人忘'); sys.exit(1)
if not os.path.isdir(ed):
    print(f'  \033[31m✗\033[0m experimental.evals 指向 {ed}，磁盘上没有'); sys.exit(1)
bad=0; n=0
for root in (ed, 'testing/grader-check'):
    if not os.path.isdir(root): continue
    for e in sorted(os.listdir(root)):
        p=os.path.join(root,e)
        if not os.path.isdir(p) or e in ('results','fixtures'): continue
        if not (os.path.exists(f'{p}/prompt.md') or os.path.exists(f'{p}/case.yaml')):
            print(f'  \033[31m✗\033[0m {p} 在 eval 目录下却既没有 prompt.md 也没有 case.yaml——它不会被当成 case，也不会有人发现'); bad=1
        else: n+=1
if bad: sys.exit(1)
print(f'  \033[32m✓\033[0m experimental.evals = {ed}，两个套件共 {n} 个 case 全部成形')
P24

echo "25. eval 判据里点名的技能必须真实存在（技能改名后，断言会静默失配）"
# 这一条守的是 per-skill 断言。它们有个官方内置的静默失效：`tool_used` on `Skill`
# 不写 arm 时**自动是 with-only**，而 with-only 判据在 with-without 两个臂里都不计分
# （官方原文：a `passed: false` with `scored: false` under a run scoring 1.0 is expected）。
# 所以 input_match 里的技能名打错一个字符，判据静默失配、分数不动、退出码 0。
#
# 免费能判的就是名字本身：权威是 skills/ 目录，和不变量 1 同一个权威。
# **判不到的**：正则本身写错（转义、JSON 形状）。那只能在真跑里正负双向量——
# 量过 `context.history_file` 重放的历史判据看不见（`Read called 0x`），
# 所以 tool_used / tool_order **无法**像 llm/regex 判据那样用 $0.06 的夹具验证。
# 这条边界写在 testing/evals/README.md，判据旁边也各写了 UNVERIFIED:。
python3 - <<'P25' || FAIL=1
import os,re,sys,glob
pkgs={d for d in os.listdir('skills') if os.path.exists(f'skills/{d}/SKILL.md')}
files=sorted(glob.glob('testing/evals/*/graders/*.md'))+sorted(glob.glob('testing/evals/*/case.yaml')) \
     +sorted(glob.glob('testing/grader-check/*/case.yaml'))
named=set(); bad=0
for f in files:
    for m in re.finditer(r'input_match:\s*[\x27"](.+?)[\x27"]\s*$', open(f,encoding='utf-8').read(), re.M):
        for cand in re.findall(r'[a-z][a-z0-9-]{3,}', m.group(1)):
            if cand in ('skill','true','false','type','name'): continue
            if cand in pkgs: named.add(cand)
            elif cand.startswith('ui-contract') or cand in ('decision-interview','spec-before-code',
                 'constraint-by-types','decision-record','deliverable-language'):
                print(f'  \033[31m✗\033[0m {f}: input_match 点名了 `{cand}`，skills/ 下没有这个包'); bad=1
if bad: sys.exit(1)
if not named:
    print('  \033[31m✗\033[0m 没有任何判据点名具体技能——`tool_used: Skill` 不带 input_match 只断言「某个技能跑了」，15 个包共用一条判据等于每个包都没有保障'); sys.exit(1)
print(f'  \033[32m✓\033[0m {len(named)}/{len(pkgs)} 个包被 per-skill 断言点名，名字全部真实：{", ".join(sorted(named))}')
print(f'  \033[33m!\033[0m 其余 {len(pkgs)-len(named)} 个包在行为层没有针对自己的断言（记在 issue #6）')
P25

echo "26. 文档里对检查编号的引用必须解析（PR #13 声称加了「第 24 条」，代码里从来没有过）"
# 这一条与别的不同类：别的守代码，它守**叙述与代码的一致**。
# CLAUDE.md 已经写了这条原则——「A hand-maintained list beside a script that checks
# the same thing is a second source of truth, and the first time they disagree the
# list becomes a lie.」ADR 正文与 PR 描述就是那份手抄清单，而它已经说过谎：
# PR #13 正文写「structure.sh 加了第 24 条」并附了一组统计，两样都不存在。
#
# 锚点是**从代码抽出来的编号集合**：编号从本文件的 `echo "N.` 行抽，文档里的引用
# 必须落在这个集合里。
#
# **第一版是指纹，我注入验出来的**：它只认「不变量 N」「检查 N」两种措辞，于是
# 「invariants.sh 加了第 99 条」——**真实发生过的那一种**——原样穿过去。
# 现在两条路一起认：(a) 与脚本名同行的任何「第 N 条」；(b) 任何位置的「不变量 N」
# 「检查 N」。
# **仍然抓不到的**（不写下来的话，下一个人会以为覆盖是完整的）：
#   · 引用跨了行——「invariants.sh 里\n第 99 条……」
#   · 完全不带这三种锚点的说法，比如「那条新加的断言」
python3 - <<'P26' || FAIL=1
import re,sys,glob
src=open('testing/structure/invariants.sh',encoding='utf-8').read()
have={int(n) for n in re.findall(r'^echo "(\d+)\.', src, re.M)}
SCRIPT=re.compile(r'invariants\.sh|structure\.sh|结构不变量')
bad=0
for f in sorted(glob.glob('docs/adr/*.md'))+['README.md','CLAUDE.md','examples/README.md']:
    try: lines=open(f,encoding='utf-8').read().splitlines()
    except OSError: continue
    for i,line in enumerate(lines,1):
        refs=set()
        if SCRIPT.search(line):                                  # (a) 与脚本名同行
            refs |= {int(n) for n in re.findall(r'第\s*(\d+)\s*条', line)}
        refs |= {int(n) for n in re.findall(r'(?:不变量|检查)\s*(\d+)', line)}   # (b) 显式措辞
        for n in sorted(refs):
            if n not in have:
                print(f'  \033[31m✗\033[0m {f}:{i} 引用了不存在的检查编号 {n}（现有 {min(have)}–{max(have)}）'); bad=1
if bad: sys.exit(1)
print(f'  \033[32m✓\033[0m 文档里的检查编号引用全部解析（本文件现有 {len(have)} 条）')
P26

echo "27. ADR 里写到的仓库内路径仍然存在（改目录之后，已接受的记录不编辑，但过期要看得见）"
# CLAUDE.md：「Accepted records are not edited.」那条规矩防的是悄悄改掉当初的决定，
# 不是让路径永远正确。testing/ 这次改名让 0002/0003/0004/0006 的路径引用全部过期。
# 修法是新立 ADR-0008 说明改名，旧记录一个字不动——但过期必须**可见**。
# 所以这条是 warn 不是 fail：它不阻止任何事，只是不让过期变成静默。
#
# `docs/ui-contract/` 排除在外，因为那是**用户项目里**的路径，不是本仓库的磁盘。
# CLAUDE.md 分得很清：`docs/adr/` 是本仓库的决定，`docs/ui-contract/adr/` 是插件写进
# 用户项目的决定。ADR-0009 钉死 `docs/ui-contract/tokens.input.json` 之后，这条检查
# 一度对它报了两处「过期」——**报得对不了，因为那个文件本来就不该在本仓库存在**。
# 一条会稳定误报的 warn，教出来的只是「这些警告可以不看」。
python3 - <<'P27'
import re,glob,os
stale=[]
for f in sorted(glob.glob('docs/adr/*.md')):
    for m in re.finditer(r'`((?:tests|evals|grader-check|testing|skills|docs|examples)/[A-Za-z0-9_./*-]+)`', open(f,encoding='utf-8').read()):
        p=m.group(1)
        if '*' in p: continue
        if p.startswith('docs/ui-contract/'): continue   # 用户项目的命名空间，见上
        if not os.path.exists(p): stale.append((os.path.basename(f), p))
for f,p in sorted(set(stale)):
    print(f'  \033[33m!\033[0m {f} 提到 `{p}`，磁盘上已经没有（已接受的记录不编辑；testing/ 改名那一批由 ADR-0008 承接）')
print('  \033[32m✓\033[0m 已检查' if not stale else f'  \033[32m✓\033[0m 已检查（{len(set(stale))} 处过期，warn 不判失败）')
P27

echo "28. 技能不依赖本插件之外的技能（装了本插件的用户不一定装了别人的）"
# 这条是被一次实测催生的：`originate.md` 的 Step 2 曾经写着
# `Call the Skill tool with "frontend-design"`，而那个技能属于另一个 marketplace，
# 装 ui-contract 不会带上它。eval 沙箱只装被测插件——29 个可见技能里没有它——
# 但**那不是沙箱的特殊情况**，任何没单独装它的用户都一样。
#
# 后果是**沉默的**：从保留的沙箱量到，同一个缺陷有两种应对——一次自己把值派生了出来，
# 一次推到「下一轮」并宣布完工（「两份规范和配置文件都已写完」）。两份产物从外面看
# 都像正常完整的交付物。那个 40–87% 之间飘的落地率，真身就是这个。
#
# 判据是**闭集**：`Call the Skill tool with "X"` 里的 X 必须是 skills/ 下真实存在的包。
# 锚点是磁盘，和不变量 1、25 同一个权威。跨插件依赖要么不写，要么走 plugin.json 的
# dependencies（而跨 marketplace 那条路默认被禁，见 ADR-0009）。
# 带 `插件:技能` 前缀的一律判红：本插件调自己的包从不写前缀（全仓库 0 处），
# 而前缀正是跨插件调用的写法——只看冒号后半段的话，`别人的插件:ui-contract-layout`
# 会因为后半段撞上本地包名而蒙混过去。
#
# ⚠ **闭集只对这一种措辞成立。** 判的是 `Call the Skill tool with "X"` 这一个句式，
# 换成散文（`use the frontend-design skill`）或别的记法就绕过去了。不追求穷举，
# 是因为这个句式是仓库里唯一在用的写法（不变量 9、11 也钉在它上面），
# 而句式一换，那两条同样会失效——真要防的是**换句式本身**，不是这一条能单独解决的。
# 扫描范围同理：`skills/*/*.md` 只有一层，目前所有技能 md 恰好都在这一层。
python3 - <<'P28' || FAIL=1
import os,re,sys,glob
pkgs={d for d in os.listdir('skills') if os.path.exists(f'skills/{d}/SKILL.md')}
bad=[]; n=0
for f in sorted(glob.glob('skills/*/*.md')):
    for m in re.finditer(r'[Cc]all the Skill tool with ["`]([a-z][a-z0-9:-]*)["`]', open(f,encoding='utf-8').read()):
        name=m.group(1); n+=1
        if ':' in name:
            bad.append((f,name,'带 `插件:技能` 前缀——那是跨插件调用的写法，本插件调自己的包不写前缀'))
        elif name not in pkgs:
            bad.append((f,name,'skills/ 下没有这个包——装了本插件的用户不一定装了它，而缺失时的行为是沉默的'))
if bad:
    for f,name,why in bad:
        print(f'  \033[31m✗\033[0m {f} 调用了 `{name}`，{why}')
    sys.exit(1)
print(f'  \033[32m✓\033[0m {n} 处技能调用全部指向本插件内的包')
P28

echo "29. 框架默认色黑名单的两份拷贝一致（产品文档 ↔ 判据 pattern）"
# 同一份名单住在两个地方：`originate.md` §Do not emit a framework default 的代码块
# （agent 照着它派生值），和 `no-framework-default-values` 判据的 `pattern`（判它有没有照做）。
# 判据文件自称「一字不差」——而那正是不变量 17 存在的理由：手抄的第二份迟早要说谎。
# 17 只管同一条判据的多份拷贝，管不到「产品文档 ↔ 判据」这一对，所以单开一条。
#
# 两个方向都要判，因为两种漂移的后果不同：
#   名单多、pattern 少 → 产品说了不许用，判据不看，**静默漏判**
#   pattern 多、名单少 → 判据判红一个产品从没被告知的值，**假阳**
# 顺带要求 pattern 里除了这些 hex 没有别的选项：加一个宽松的分支（比如 `blue`）
# 会让这条比对通过而判据行为全变。
python3 - <<'P29' || FAIL=1
import re,sys
DOC='skills/ui-contract-design/originate.md'
GRD='testing/evals/greenfield-originate/graders/no-framework-default-values.md'
H='### Do not emit a framework default'
src=open(DOC,encoding='utf-8').read()
i=src.find(H)
if i<0:
    print(f'  \033[31m✗\033[0m {DOC} 里没有 `{H}` 这一节——名单搬家了，判据还指着它'); sys.exit(1)
blk=re.search(r'```\n(.*?)```', src[i:], re.S)
if not blk:
    print(f'  \033[31m✗\033[0m {H} 一节里没有代码块，名单读不出来'); sys.exit(1)
doc={h.lower() for h in re.findall(r'#[0-9a-fA-F]{6}', blk.group(1))}
g=open(GRD,encoding='utf-8').read()
mp=re.search(r'^pattern: "([^"]*)"', g, re.M)
if not mp:
    print(f'  \033[31m✗\033[0m {GRD} 的 frontmatter 里没有 pattern'); sys.exit(1)
alts=[a.strip() for a in mp.group(1).split('|')]
bad_alt=[a for a in alts if not re.fullmatch(r'#[0-9a-fA-F]{6}', a)]
grd={a.lower() for a in alts if re.fullmatch(r'#[0-9a-fA-F]{6}', a)}
fail=0
if bad_alt:
    print(f'  \033[31m✗\033[0m 判据 pattern 里有不是 hex 的分支：{", ".join(bad_alt)}——这条比对管不住它的行为'); fail=1
if doc-grd:
    print(f'  \033[31m✗\033[0m 名单里有、判据 pattern 里没有：{", ".join(sorted(doc-grd))}——产品说了不许用，判据不看（静默漏判）'); fail=1
if grd-doc:
    print(f'  \033[31m✗\033[0m 判据 pattern 里有、名单里没有：{", ".join(sorted(grd-doc))}——判据会判红一个产品从没告诉过 agent 的值（假阳）'); fail=1
if fail: sys.exit(1)
print(f'  \033[32m✓\033[0m {len(doc)} 个默认色值，产品文档与判据 pattern 一致')
P29

echo "30. 活文档里写到的开发树路径必须存在（skills/ 与 examples/，过期即失败）"
# 不变量 27 的另一半，而且严格程度相反。27 判的是 `docs/adr/`：已接受的记录不编辑，
# 所以路径过期只 warn。这一条判的是 `skills/` 与 `examples/`——**活文档**，
# 没有「不编辑」的豁免，写错了就是错的，所以 fail。
#
# 它是被这次 review 催生的：ADR-0008 把 tests/ 改名成 testing/ 之后，
# `skills/ui-contract-wireframe/` 里有 5 处、`examples/README.md` 里有 1 处
# 仍然写着 `tests/structure.sh`。27 只扫 docs/adr/，一处都没看见。
# 而 skills/ 是**唯一会安装到用户机器**的目录：那 5 处是发给用户的错误指路。
#
# 只认开发树的命名空间（tests / testing / evals / grader-check / docs/adr）。
# skills/ 里绝大多数路径说的是**用户项目**（`layout.md`、`docs/ui-contract/config.md`、
# `src/ui/region.tsx`），那些在本仓库磁盘上本来就不该存在，一律不判。
python3 - <<'P30' || FAIL=1
import re,os,sys,glob
NS=re.compile(r'`((?:tests|testing|evals|grader-check|docs/adr)/[A-Za-z0-9_./*-]+)`')
bad=[]; n=0
files=[f for f in glob.glob('skills/**/*', recursive=True)
       if os.path.isfile(f) and (f.endswith('.md') or f.endswith('.template'))]
files+=[f for f in glob.glob('examples/**/*.md', recursive=True) if os.path.isfile(f)]
for f in sorted(files):
    for m in NS.finditer(open(f,encoding='utf-8').read()):
        p=m.group(1)
        if '*' in p: continue
        n+=1
        if not os.path.exists(p): bad.append((f,p))
if bad:
    for f,p in sorted(set(bad)):
        print(f'  \033[31m✗\033[0m {f} 提到 `{p}`，磁盘上没有——活文档没有「不编辑」的豁免，而 skills/ 会安装到用户机器')
    sys.exit(1)
print(f'  \033[32m✓\033[0m {n} 处开发树路径引用全部解析')
P30

echo "31. 器具与体检对「什么算一对」的定义一致（同一个阈值的两个消费者）"
# `design-md-outline.md` 写明这个阈值有两个消费者：调值器具实时判，体检脚本几个月后再判，
# 而且「两者都不硬编码」。但**判什么**此前没人对齐：器具的 pairs() 有基础对特判
# （`background|page|surface` 配 `foreground|text`），体检脚本没有。
# 后果实测过：白底白字（1.00:1）在体检里报 "no hex pairs" 然后 exit 0，在器具里是红的。
# 同一份 token 文件，两个工具两个答案，没有任何东西报错——正是 `wire.tsx` 那段注释
# 警告过的形状。
#
# 两边一个是 awk 一个是 JS，比不了代码，能比的是**名单本身**：两个候选集合的字面量
# 必须同时出现在两个文件里。它拦不住「改了配对逻辑但没动名单」，拦得住
# 「给一边加了个别名，忘了另一边」——那是这次真实发生过的那一种。
# 判据是**提取出来比对**，不是「这个字面量在不在文件里」。第一版就是子串检查，
# 而给一边加个别名（`background|page|surface|canvas`）时原串仍是子串——绿着。
# 这两条 effectiveness 用例当场把它抓了出来。
python3 - <<'P31' || FAIL=1
import re,sys
INSTR='skills/ui-contract-design/assets/theme-studio.html.template'
AUDIT='skills/ui-contract-audit/assets/audit.sh.template'
# 两边碰巧都写成 `/^(a|b|c)$/`：器具是 JS 正则，体检是 awk 正则，同一个记法。
G=re.compile(r'\^\(([a-z|]+)\)\$')
def groups(f):
    return sorted(tuple(sorted(m.split('|'))) for m in G.findall(open(f,encoding='utf-8').read()))
a, b = groups(INSTR), groups(AUDIT)
if not a:
    print(f'  \033[31m✗\033[0m {INSTR} 里一个 `^(...)$` 名单都没有——配对规则改了记法，这条检查已经瞎了'); sys.exit(1)
if a != b:
    print(f'  \033[31m✗\033[0m 器具与体检的基础对名单分了家：')
    print(f'      器具 {a}')
    print(f'      体检 {b}')
    print(f'      同一份 token 文件会在两个工具里得到两个答案，而没有任何东西报错')
    sys.exit(1)
print(f'  \033[32m✓\033[0m 器具与体检的基础对名单一致（{len(a)} 组）')
P31

echo "13. 包体量（ADR-0003：某包 SKILL.md 长期不足 30 行，说明切早了，应并回上游包）"
for d in skills/*/; do
  n=$(wc -l < "$d/SKILL.md"); b=$(basename "$d")
  [ "$n" -lt 30 ] && warn "$b 只有 $n 行，接近复议线（这是警告，不判失败）"
done
ok "已检查"

echo "32. 每条检查都有有效性用例，且那句覆盖承诺与实际条数相符"
# 这一条守的是另一份测试的**承诺**，不是产品。理由写在 invariants-effectiveness.sh
# 第 4 行它自己身上：「这一行是承诺，别让它变成散文」——然后它变成了散文。
# 加这条的时候，那句话写着 1–30，而这里有 31 条检查。
#
# 「一条检查」和「它的用例」之间没有缝：两边靠字符串里的一个编号配对。加一条检查时
# 没有任何东西提醒你它缺用例，删一条时也没有东西告诉你它的用例现在是死的。
# CLAUDE.md 说「新断言没有用例就不算完成」——在此之前，那条规则靠人读注释执行。
#
# **这条抓不到的**：一个存在但打不中的用例（注入锚点失效那种）。那由 0c 自己的
# 「注入本身失败」分支报。这里只数「有没有」，不数「打不打得中」。
python3 - <<'P32' || FAIL=1
import re,sys
CHK='testing/structure/invariants.sh'
EFF='testing/structure/invariants-effectiveness.sh'
try:
    chk=open(CHK,encoding='utf-8').read(); eff=open(EFF,encoding='utf-8').read()
except OSError as e:
    print(f'  \033[31m✗\033[0m 读不到 {e.filename}'); sys.exit(1)
nums=sorted({int(n) for n in re.findall(r'^echo "(\d+)\.', chk, re.M)})
covered={int(n) for n in re.findall(r'^run_(?:case|out) [^"]*"(\d+)[a-z]? ·', eff, re.M)}
bad=0
missing=[n for n in nums if n not in covered]
if missing:
    print(f'  \033[31m✗\033[0m 这些检查没有任何用例: {missing}——CLAUDE.md 说没有用例就不算完成'); bad=1
# 锚在**行首的注释**上，不是在那串字里。量过：用例的参数里也含着同一串字，
# 于是注入把承诺那一行换掉之后，正则在用例自己身上又匹配到一次，检查绿着放过。
m=re.search(r'^# 覆盖范围[^\n]*\*\*(\d+)[–-](\d+) 全部有用例\*\*', eff, re.M)
if not m:
    print('  \033[31m✗\033[0m 找不到那句覆盖承诺——它是这份测试唯一的全称声明，不许消失'); bad=1
elif int(m.group(2)) != max(nums):
    print(f'  \033[31m✗\033[0m 覆盖承诺写着 {m.group(1)}–{m.group(2)}，实际有 {max(nums)} 条检查'
          f'——那一行自己说过「别让它变成散文」'); bad=1
if not bad:
    print(f'  \033[32m✓\033[0m {len(nums)} 条检查全部有用例，承诺与条数相符')
sys.exit(bad)
P32

echo "33. 颜色知识的三份拷贝仍然逐字相同（不生成，比对——同检查 17）"
# 「一个颜色值长什么样」是一份知识，住在三个地方：本文件的检查 22、线框的
# check-colours.sh、体检的 audit.sh。它们跑在三个引擎里（Python re / grep -E /
# grep -rnE），所以**赋值写法**必然不同，但**模式本身**逐字相同——验过，同一串
# POSIX ERE 在三处行为一致。
#
# 为什么比对而不是生成：这个仓库对「一个事实三个地方」已经有形态了（检查 17 对
# eval 判据做的就是这件事）。比对不需要新概念、不需要构建步骤，也不需要回答
# 「一个要发到别人仓库里的模板，生成步骤跑在哪」。
#
# 这条存在之前它们已经三向漂了，每一份都缺着另外两份有的东西：audit.sh 只认
# 6 位 hex、一个 Tailwind 前缀都没有，于是业务代码里的 `#fff` 和 `bg-blue-500`
# 是绿的；另外两份缺 lab()/lch()/color()。现在的值是并集。
#
# **抓不到的**：三份一起被改错。比对只保证一致，不保证正确——正确性靠
# audit-effectiveness 与 0c 里那些注入用例。
python3 - <<'P33' || FAIL=1
import re,sys
F=['testing/structure/invariants.sh',
   'skills/ui-contract-wireframe/assets/check-colours.sh.template',
   'skills/ui-contract-audit/assets/audit.sh.template']
vals={}
for f in F:
    try: t=open(f,encoding='utf-8').read()
    except OSError: print(f'  \033[31m✗\033[0m 读不到 {f}'); sys.exit(1)
    got={}
    for key in ('COLOUR_NOTATION','COLOUR_NAMED'):
        # 只剥赋值语法（r 前缀与引号），不碰模式本身——规范化模式等于再造一个
        # 「什么算相同」的实现，而那正是这条检查要治的病。
        m=re.search(r"^%s\s*=\s*r?'(.*)'\s*$" % key, t, re.M)
        if not m:
            print(f'  \033[31m✗\033[0m {f} 里找不到 {key}——三份拷贝必须都带哨兵'); sys.exit(1)
        got[key]=m.group(1)
    vals[f]=got
bad=0
for key in ('COLOUR_NOTATION','COLOUR_NAMED'):
    seen={vals[f][key] for f in F}
    if len(seen)!=1:
        print(f'  \033[31m✗\033[0m {key} 三份不一致：')
        for f in F: print(f'      {f}: {vals[f][key][:70]}…')
        bad=1
if not bad: print('  \033[32m✓\033[0m 颜色记法与具名名单三份逐字相同')
sys.exit(bad)
P33

echo "34. skills/ 里不出现插件自身开发树的引用（install.sh 只装 skills/，其余任何读者都拿不到）"
# 模板是 **copy and adapt**：读进来一份、改写出去一份，最后落进**用户的仓库**。
# 所以模板注释有两个读者——改模板的维护者，和拿到拷贝的人。现在有一批只对前者
# 有意义：`ADR-0007`、`testing/structure/invariants.sh`。用户打开自己项目里的
# inspect.tsx 读到「See ADR-0007」，那份文档他没有，也无从跟进。
#
# 而维护者那一半也未必该留在这里：凡是已经有机械检查守着的事（颜色记法三份一致
# 由第 33 条守着），注释就是那个事实的第二份拷贝——同检查 17 的理由。
#
# **锚是一个封闭集**：这个插件自己开发树里的标识符。说清楚它放过什么——
# 不带标识符的过去时叙述（「it used to be eleven」「all three were once hardcoded
# to React」「it was line-wise」）**一条都抓不到**，那一类只能靠人读。
#
# 2026-08-26 落地时是 warn（当时有 15 处），同日把那 15 处清干净之后**转为失败**。
# 清掉的是指针，不是结论：`see ADR-0012` 前面那句「豁免是一个文件，不是文件里的标记」
# 本身留着——用户读得懂它，读不懂那个编号。
# 范围是整个 skills/，不只是 assets/：`install.sh` 只拷 skills/，所以 docs/adr/ 与
# testing/ 对**运行时的 agent 也不存在**，不只是对用户。`docs/adr/` 本身不在名单里——
# 那三个字在技能里指的是**用户仓库自己的** ADR 目录，是合法用法。
#
# 目录名后面是 `[A-Za-z]` 不是 `[a-z]`：写成小写时，路径里紧跟斜杠的那一段
# 只要首字母大写就**匹配不到**。真实存在的那个是 `examples/README.md`——
# 这个目录里唯一的顶层文件，也是最可能被技能引用的那个。
# （`testing/evals/README.md` 不在此列，它被 `testing/e` 接住。）
# 2026-08-26 量到时 skills/ 里恰好没有大写拼法，所以这个洞一直绿着。
# 「能挡住想到的那种写法」和「能挡住同一个违规换个拼法」是两件事，见 CLAUDE.md。
HITS=$(grep -rnE 'ADR-[0-9]{4}|issue #[0-9]+|testing/[A-Za-z]|examples/[A-Za-z]|grader-check' skills/ 2>/dev/null)
if [ -n "$HITS" ]; then
  n=$(printf '%s\n' "$HITS" | wc -l | tr -d ' ')
  no "$n 处引用了插件自身的开发树（install.sh 只装 skills/，运行时拿不到）"
  printf '%s\n' "$HITS" | sed 's|^skills/|      |' | cut -c1-110
else
  ok "skills/ 里没有指向开发树的引用"
fi

echo "35. 示例里的 check-colours.sh 与模板同源（实现可以分家，而且分过一次）"
# 这条是买来的。示例里那份当时停在**被证伪的旧实现**上：检查 2 枚举
# `const|function|type` 三种拼法，对 `export async function Sneaky()` 打印
# 「apparatus exports match the declared list」——模板注释里明写过这个穿透，
# 示例却还留着它。两份各自演进了，而在此之前没有任何东西在比。
#
# 不变量 33 比的是三份里的 `COLOUR_NOTATION` / `COLOUR_NAMED` 两个**值**，
# 比不到实现；示例也根本不在那三份之列。所以那条全绿，这个分家照样发生。
#
# 锚：**逐行比对，除去两类刻意允许不同的行**——模板顶部那句 TODO（它的作用就是被删掉），
# 以及三行路径赋值（模板让你调它们；示例今天没调，将来调了也不该判红）。
# 什么能过：把实现改动伪装成路径赋值行的一部分。那需要在一行赋值里塞进逻辑，
# 在 diff 里比它想躲的那次改动更显眼。
python3 - <<'P35' || FAIL=1
import re,sys
TPL='skills/ui-contract-wireframe/assets/check-colours.sh.template'
EX='examples/admin-console/check-colours.sh'
try:
    tpl=open(TPL,encoding='utf-8').read().split('\n')
    ex=open(EX,encoding='utf-8').read().split('\n')
except OSError as e:
    print(f'  \033[31m✗\033[0m 读不到 {e.filename}'); sys.exit(1)
def strip(lines):
    out=[]
    for l in lines:
        if 'TODO adjust' in l: continue
        if re.match(r'^(WIRE_SRC|APPARATUS|PARTS)=', l): continue
        out.append(l)
    return out
a,b=strip(tpl),strip(ex)
if a==b:
    print('  \033[32m✓\033[0m 示例的 check-colours.sh 与模板同源'); sys.exit(0)
print('  \033[31m✗\033[0m 示例的 check-colours.sh 与模板已经分家——用户拿到的是模板，'
      '示例教的是另一份')
for i,(x,y) in enumerate(zip(a,b)):
    if x!=y:
        print(f'      第一处差异（去掉路径行后的第 {i+1} 行）：')
        print(f'        模板: {x[:90]}')
        print(f'        示例: {y[:90]}')
        break
else:
    print(f'      行数不同：模板 {len(a)} 行，示例 {len(b)} 行')
sys.exit(1)
P35

# 总结行必须是最后一行输出。它曾打印在 32/33/34 之前：那几条判红时，终端上先出现
# 绿色的「结构不变量全部通过」，红叉跟在后面。退出码一直是对的，run.sh 也照样报失败，
# 但那一行本身是假的——而它正是扫一眼输出的人唯一会读的那一行。
# 这个仓库反复吃亏的形状是「从输出看起来对，推出机制有效」，这次发生在守卫自己身上。
printf '\n'
[ $FAIL -eq 0 ] && printf '\033[32m结构不变量全部通过\033[0m\n' || printf '\033[31m结构不变量有失败\033[0m\n'

exit $FAIL
