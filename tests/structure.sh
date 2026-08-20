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

echo "13. 包体量（ADR-0003：某包 SKILL.md 长期不足 30 行，说明切早了，应并回上游包）"
for d in skills/*/; do
  n=$(wc -l < "$d/SKILL.md"); b=$(basename "$d")
  [ "$n" -lt 30 ] && warn "$b 只有 $n 行，接近复议线（这是警告，不判失败）"
done
ok "已检查"

printf '\n'
[ $FAIL -eq 0 ] && printf '\033[32m结构不变量全部通过\033[0m\n' || printf '\033[31m结构不变量有失败\033[0m\n'
exit $FAIL
