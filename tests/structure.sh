#!/bin/sh
# 结构不变量。不花钱、不需要 agent、秒级完成。
#
# 单一来源是**磁盘**：skills/ 下每个含 SKILL.md 的目录就是一个包。
# 两份 manifest 与 README 索引都只是它的投影，由第 1 项对账。
# 这些不变量一旦破掉，插件会装不全、组合链会断、或索引会说谎。
cd "$(dirname "$0")/.." || exit 1
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
for s in decision-interview spec-before-code constraint-by-types decision-record deliverable-language; do
  [ -f "skills/$s/SKILL.md" ] || { no "$s 缺失"; continue; }
  h=$(grep -oiE 'layout\.md|design\.md|wireframe|region|allowlist|界面|UI contract|区域' "skills/$s/SKILL.md" | sort -u | tr '\n' ' ')
  [ -z "$h" ] && ok "$s" || no "$s 出现 UI 词汇: $h"
done

echo "6. 无跨包相对路径引用（装完后各包是孤立目录，跨包路径必失效）"
X=$(grep -rn '](\.\./' skills/ 2>/dev/null)
[ -z "$X" ] && ok "无 ../ 跨包引用" || no "$X"

echo "7. 包内 markdown 链接不断"
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
X=$(find skills -path '*/tests/*' -o -path '*/evals/*' -o -path '*/examples/*' 2>/dev/null)
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
for f in sorted(glob.glob('evals/*/graders/*.md')):
    src=open(f,encoding='utf-8').read()
    name=f.split('/')[-1][:-3]
    fm=src.split('---')[1]
    mp=re.search(r'^pattern: "([^"]*)"', fm, re.M)
    if mp: found.append((name,'pattern',mp.group(1),f))
    else:
        body=re.sub(r'^#[^\n]*\n','',src.split('---',2)[2].lstrip('\n'))
        found.append((name,'criteria',body,f))
for f in sorted(glob.glob('evals/*/case.yaml'))+sorted(glob.glob('grader-check/*/case.yaml')):
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
D="skills/ui-contract-design/SKILL.md"
R1=$(grep -c 'tokens\.input\.json.*input record' "$D")
R2=$(grep -c 'token file.*currently correct' "$D")
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
X=$(grep -niE '<nav|sidebar|breadcrumb|<header|<footer' skills/ui-contract-design/assets/theme-studio.html.template 2>/dev/null)
[ -z "$X" ] && ok "样张只有通用控件" || no "模板里有 IA 载体: $X"

echo "22. 线框模板里颜色的**值**只在 NEUTRAL 一处（ADR-0006 把判据从「没有颜色」换成「没有颜色的值」）"
# 一条被推翻的决定需要机械守卫，不是一句叮嘱。ADR-0001 当初禁掉换肤预览，
# 靠的是「线框里没有颜色」——那条好守但也挡住了用户真正要看的东西。
# 换成「没有颜色的值」之后，线框可以换肤而依然不可能成为第二个视觉真相源，
# 但**只有这条断言在时才成立**：值一旦漏到 NEUTRAL 之外，两句话就同时失效。
# 例外只有 inspect 装置那一块（标注层 + 换肤横幅）：它们不是产品表面，刻意不跟皮肤
# 走，且由模板里的哨兵注释声明，不靠这里猜颜色名。横幅尤其不能跟——量到过：
# 用 --wire-strong 画它，会被它正在警告的那套皮换肤，浅色主题下白底白字直接消失。
#
# **这条抓不到的**：往 NEUTRAL 里直接加一个品牌色。NEUTRAL 内是允许写值的——
# 那是线框自己的灰——所以「加进去的是不是灰」这件事只能靠人评审。量过：注入
# `'--wire-brand': '#2563eb'` 仍然 exit 0。不写下来的话，下一个读这条断言的人
# 会以为它守住了整件事。
python3 - <<'P22' || FAIL=1
import re,sys
p='skills/ui-contract-wireframe/assets/wire.tsx.template'
try: s=open(p,encoding='utf-8').read()
except OSError: print('  \033[31m✗\033[0m 找不到 '+p); sys.exit(1)
bad=0
m=re.search(r'export const NEUTRAL[^{]*\{(.*?)\n\}', s, re.S)
if not m:
    print('  \033[31m✗\033[0m 模板里找不到 NEUTRAL——它是「值只在一处」的载体'); sys.exit(1)
rest = s[:m.start()] + s[m.end():]
# 标注层是**声明出来的**例外，按模板里的哨兵剔除整块——不是靠猜哪些颜色名该放过。
# 猜颜色名的版本第一次跑就漏判了 sky-*（区域徽标与虚线框），而那正是合法的那批。
a = re.search(r'INSPECT CHROME BEGIN(.*?)INSPECT CHROME END', rest, re.S)
if not a:
    print('  \033[31m✗\033[0m 模板里没有 INSPECT CHROME 哨兵——例外必须是声明的，不是猜的'); sys.exit(1)
rest = rest[:a.start()] + rest[a.end():]
leaks = re.findall(r'#[0-9a-fA-F]{3,8}\b|\brgba?\(|\boklch\(|\bhsla?\(|\b(?:bg|text|border|ring|fill|stroke)-(?:red|blue|green|yellow|amber|orange|purple|pink|indigo|teal|cyan|violet|rose|lime|emerald|sky|fuchsia|slate|zinc|stone|gray|grey|neutral)-\d{2,3}', rest)
if leaks:
    print(f'  \033[31m✗\033[0m NEUTRAL 之外出现颜色值: {sorted(set(leaks))[:8]}'); bad=1
skin=re.search(r'export const SKIN[^{]*\{(.*?)\n\}', s, re.S)
if not skin:
    print('  \033[31m✗\033[0m 模板里找不到 SKIN 映射表'); bad=1
else:
    filled=[v for v in re.findall(r":\s*'([^']*)'", skin.group(1)) if v.strip()]
    if filled:
        print(f'  \033[31m✗\033[0m SKIN 里填了 token 名: {filled}——design.md 才是名字权威'); bad=1
if not bad: print('  \033[32m✓\033[0m 颜色值只在 NEUTRAL，SKIN 出厂全空')
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
python3 - <<'P23' || FAIL=1
import re,sys
T='skills/ui-contract-wireframe/assets/wire.tsx.template'
E='examples/admin-console/wireframe/src/wire.tsx'
R='examples/README.md'
def exports(p):
    return set(re.findall(r'^export (?:const|function|type)\s+([A-Za-z_][A-Za-z0-9_]*)',
                          open(p,encoding='utf-8').read(), re.M))
try:
    t, e, rd = exports(T), exports(E), open(R,encoding='utf-8').read()
except OSError as err:
    print(f'  \033[31m✗\033[0m 读不到 {err.filename}'); sys.exit(1)
missing = sorted(n for n in t - e if f'`{n}`' not in rd)
if missing:
    print(f'  \033[31m✗\033[0m 模板导出了这些、示例没有、README 也没写明: {missing}'); sys.exit(1)
lag = sorted(t - e)
print(f'  \033[32m✓\033[0m 示例落后 {len(lag)} 个符号，全部在 README 里点了名'
      if lag else '  \033[32m✓\033[0m 示例与模板的导出一致')
P23

echo "13. 包体量（ADR-0003：某包 SKILL.md 长期不足 30 行，说明切早了，应并回上游包）"
for d in skills/*/; do
  n=$(wc -l < "$d/SKILL.md"); b=$(basename "$d")
  [ "$n" -lt 30 ] && warn "$b 只有 $n 行，接近复议线（这是警告，不判失败）"
done
ok "已检查"

printf '\n'
[ $FAIL -eq 0 ] && printf '\033[32m结构不变量全部通过\033[0m\n' || printf '\033[31m结构不变量有失败\033[0m\n'
exit $FAIL
