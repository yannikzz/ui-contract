#!/bin/sh
# check-colours.sh.template 的每条检查**真的能失败**。
#
# 为什么需要这个：不变量 22 守着同一条规则，但它是一份 **Python 重实现**，读的是模板
# 文件的内容。随线框交付给用户的那个 **shell 脚本本身，此前从来没有被执行过**——
# 22 全绿而模板里的 awk 写错、或者在 dash 下行为不同，没有任何东西会发现。
# 同一个道理，同一个形状：`audit-effectiveness.sh` 之于 `audit.sh.template`。
#
# 这不是第三份规则实现。它一行规则也不重写，只跑那个脚本，注入违规，看退出码。
#
# 这条测试第一次跑就抓到了东西，记在这里免得被读成假想威胁：
# `examples/admin-console/check-colours.sh` 当时停在**被证伪的旧实现**上
# （检查 2 枚举 `const|function|type` 三种拼法），对 `export async function Sneaky()`
# 打印「apparatus exports match the declared list」——模板注释里明写过这个穿透，
# 而示例里那份还留着它。示例现在与模板同步，不变量 35 盯着不再分家。
#
# 每个用例：拷线框 → 注入一处违规 → 跑模板脚本 → 期望的退出码必须出现。
# 干净的那条必须绿——只测红的话，一个 `exit 1` 就能骗过整份测试。
cd "$(dirname "$0")/../.." || exit 1
FAIL=0
CASES=0
. testing/structure/lib.sh

TEMPLATE="skills/ui-contract-wireframe/assets/check-colours.sh.template"
# 夹具是**示例里的真实线框**，不是另造一份。理由：它是这个脚本唯一的真实消费者，
# 而多一份夹具就是多一处会各自漂移的拷贝。代价说清楚：示例重构会让注入锚点失效，
# 那时下面会报「注入本身失败」而不是绿着跳过。
FIXTURE="examples/admin-console/.ui-contract-local"
WIRE="wireframe/src"

EFF_PREPARE(){
  mkdir -p "$1/.ui-contract-local/wireframe" &&
  cp -R "$FIXTURE/$WIRE" "$1/.ui-contract-local/wireframe/" &&
  cp "$TEMPLATE" "$1/check-colours.sh"
}
EFF_RUN(){ "$SH" ./check-colours.sh 2>&1; }

# 旧签名保持不变：调用点全是 run <期望退出码> <说明> <注入命令>。
run(){ run_case "$@"; }
[ -f "$TEMPLATE" ] || { no "找不到 $TEMPLATE"; exit 1; }
[ -d "$FIXTURE/$WIRE" ] || { no "找不到 $FIXTURE/$WIRE"; exit 1; }

# 模板自称要能在 dash 下跑，所以优先用 dash，顺便守住这条。
SH=$(command -v dash 2>/dev/null || command -v sh)

CASES=0

S="\$W"; P=".ui-contract-local/wireframe/src"

echo "A. 基线"
run 0 "干净的线框 exit 0（只测红的话，一个 exit 1 就能骗过整份测试）" "true"

echo "B. 检查 1 · 颜色值只在 NEUTRAL 与装置文件"
run 1 "1 · NEUTRAL 之外写死六位十六进制" \
  "printf '\nconst brand = \"#2563eb\"\n' >> $P/structure.ts"
run 1 "1 · 换成三位十六进制（记法边界，旧版只认六位）" \
  "printf '\nconst brand = \"#fff\"\n' >> $P/structure.ts"
run 1 "1 · 换成 Tailwind 色阶（不是十六进制，也是值）" \
  "printf '\nconst cls = \"bg-blue-500\"\n' >> $P/structure.ts"
run 1 "1 · 换成 CSS 具名颜色（记法外的颜色）" \
  "printf '\nconst s = { color: \"crimson\" }\n' >> $P/structure.ts"
run 1 "1 · 泄漏在 .css 里（覆盖面不止 .ts/.tsx）" \
  "printf '\n.leak { background: #2563eb; }\n' >> $P/index.css"
# 下面两条钉的是**不许乱红**的一半。一个只会红的检查和一个只会绿的检查一样没用。
run 0 "1 · 装置文件里写死颜色不判红（豁免就是这个意思）" \
  "printf '\nconst c = \"#2563eb\"\n' >> $P/inspect.tsx"
# ⚠ 注入必须**同时**给这个新角色一个 SKIN 决定，否则退出码是检查 3 给的，
# 这条用例就不再测它自称在测的东西（首跑就踩了：期望 0 实得 1）。
# 顺带一个值得记的差异：不变量 22 的注释写着「量过：注入 '--wire-brand' 仍然 exit 0」——
# 那是对模板文件的 Python 检查，它**没有检查 3 这一层**。同一个注入在两份实现下退出码
# 不同，而这正是本文件存在的理由：跑 Python 重实现，量不到 shell 脚本的行为。
run 0 "1 · 往 NEUTRAL 里加品牌色抓不到（模板自己写明的漏口，不是回归）" \
  "python3 -c \"import io;p='$P/wire.tsx';s=io.open(p,encoding='utf-8').read();s=s.replace(\\\"'--wire-surface': '#ffffff',\\\",\\\"'--wire-surface': '#ffffff',\n  '--wire-brand': '#2563eb',\\\",1);s=s.replace(\\\"'--wire-surface': '--color-surface-raised',\\\",\\\"'--wire-surface': '--color-surface-raised',\n  '--wire-brand': '',\\\",1);io.open(p,'w',encoding='utf-8').write(s)\""

echo "C. 检查 2 · 装置文件只导出声明过的名字"
# 这四条各换一种拼法。旧实现枚举 const|function|type，四条全部从中间走过去，
# 而示例里那份当时正停在旧实现上——这不是假想，是本文件第一次跑时实测到的。
run 1 "2 · 未声明的导出（export const）" \
  "printf '\nexport const Sneaky = 1\n' >> $P/inspect.tsx"
run 1 "2 · 换成 export async function（旧锚只认三种拼法）" \
  "printf '\nexport async function Sneaky() { return \"#2563eb\" }\n' >> $P/inspect.tsx"
run 1 "2 · 换成 export { X as Y } 名单形式（发布的是 Y）" \
  "printf '\nconst Hidden = 1\nexport { Hidden as Sneaky }\n' >> $P/inspect.tsx"
run 1 "2 · 换成 export default（名单点不到名的导出应判红）" \
  "printf '\nexport default function Sneaky() { return null }\n' >> $P/inspect.tsx"
run 1 "2 · 删掉 APPARATUS: 声明行（缺席不是「没声明任何东西」）" \
  "python3 -c \"import io;p='$P/inspect.tsx';L=io.open(p,encoding='utf-8').readlines();io.open(p,'w',encoding='utf-8').writelines([l for l in L if 'APPARATUS:' not in l])\""
run 0 "2 · 名单里多一个尚未存在的名字不判红（名单是上界）" \
  "python3 -c \"import io;p='$P/inspect.tsx';s=io.open(p,encoding='utf-8').read();s=s.replace('APPARATUS: ','APPARATUS: NotYetWritten ',1);io.open(p,'w',encoding='utf-8').write(s)\""
# 下面三条钉的是**解构导出**。旧实现没有解构分支：`export const [c] = y` 会把 `[c]` 削成空、
# 走过 `=`，打印出右边的 `y`——一个根本不是导出的名字。于是第一条曾经因为**错误的理由**判红
# （报的是不存在的 `y`），第二条曾经**假红**（`c` 已声明，却因为报 `y` 而挂）。
# 两条注释当时都写着「取不到名字」，和实际行为相反。第三条钉对象解构只取到第一个名字那次漏报。
#
# ⚠ **三条里只有后两条有判别力，第一条没有，写在这里而不是让人以为有。** 把解构分支退回旧实现
# 实测过：第一条**新旧都绿**——旧实现报的是右值 `y`，`y` 也不在名单里，于是**因为错误的理由
# 拿到了正确的退出码**。它守的是「报出来的名字对不对」，而退出码看不见名字。后两条各自会红
# （第二条旧实现假红，第三条旧实现漏报），分家真的发生时是它们出声。
run 1 "2 · 数组解构导出未声明（报的必须是绑定名 c，不是右边的 y）" \
  "printf '\nconst y = [1]\nexport const [Sneaky] = y\n' >> $P/inspect.tsx"
run 0 "2 · 数组解构导出已声明不判红（旧实现在这里报右值，假红）" \
  "python3 -c \"import io;p='$P/inspect.tsx';s=io.open(p,encoding='utf-8').read();s=s.replace('APPARATUS: ','APPARATUS: Bound ',1);s+='\nconst src = [1]\nexport const [Bound] = src\n';io.open(p,'w',encoding='utf-8').write(s)\""
run 1 "2 · 对象解构导出的第二个名字未声明（旧实现只取得到第一个）" \
  "python3 -c \"import io;p='$P/inspect.tsx';s=io.open(p,encoding='utf-8').read();s=s.replace('APPARATUS: ','APPARATUS: First ',1);s+='\nconst o = { First: 1, Sneaky: 2 }\nexport const { First, Sneaky } = o\n';io.open(p,'w',encoding='utf-8').write(s)\""

echo "D. 检查 3 · 每个 NEUTRAL 角色在 SKIN 里有决定"
run 1 "3 · NEUTRAL 长出一个角色而 SKIN 里没有（线框在发明规范）" \
  "python3 -c \"import io;p='$P/wire.tsx';s=io.open(p,encoding='utf-8').read();s=s.replace(\\\"'--wire-canvas': '#fafafa',\\\",\\\"'--wire-canvas': '#fafafa',\n  '--wire-newrole': '#eeeeee',\\\",1);io.open(p,'w',encoding='utf-8').write(s)\""
run 0 "3 · SKIN 里映射成空字符串不判红（空是决定，缺席才不是）" \
  "python3 -c \"import io;p='$P/wire.tsx';s=io.open(p,encoding='utf-8').read();s=s.replace(\\\"'--wire-canvas': '#fafafa',\\\",\\\"'--wire-canvas': '#fafafa',\n  '--wire-newrole': '#eeeeee',\\\",1);s=s.replace(\\\"'--wire-surface': '--color-surface-raised',\\\",\\\"'--wire-surface': '--color-surface-raised',\n  '--wire-newrole': '',\\\",1);io.open(p,'w',encoding='utf-8').write(s)\""

echo "E. 没有线框时"
run 2 "盘上没有线框 → exit 2，不是绿也不是红（全新 clone 后的正常状态）" \
  "rm -rf $P"

printf '\n'
[ $FAIL -eq 0 ] && printf '  \033[32m%s 个用例全部符合预期（%s）\033[0m\n' "$CASES" "$(basename "$SH")" \
                || printf '  \033[31m有检查名存实亡\033[0m\n'
exit $FAIL

