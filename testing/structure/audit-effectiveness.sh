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
cd "$(dirname "$0")/../.." || exit 1
FAIL=0
CASES=0
. testing/structure/lib.sh

TEMPLATE="skills/ui-contract-audit/assets/audit.sh.template"
FIXTURE="testing/structure/fixtures/audit-project"
[ -f "$TEMPLATE" ] || { no "找不到 $TEMPLATE"; exit 1; }
[ -d "$FIXTURE" ]  || { no "找不到 $FIXTURE"; exit 1; }

# 模板自称要能在 dash 下跑，所以优先用 dash 跑，顺便守住这条。
SH=$(command -v dash 2>/dev/null || command -v sh)

EFF_PREPARE(){ cp -R "$FIXTURE"/. "$1"/ && cp "$TEMPLATE" "$1/audit.sh"; }
EFF_RUN(){ "$SH" ./audit.sh 2>&1; }


# 改夹具白名单的**每一行**，而不是只改表头：drop 删掉最后一列（模型漏写那一列时的真实形态），
# add 在最后追加一列尺寸（大纲 §2 允许的第五列）。只改表头的话，测的是一张自相矛盾的表。
lastcol(){ # lastcol <drop|add>
  python3 - "$1" <<'PY'
import io,re,sys
p='layout.md'; s=io.open(p,encoding='utf-8').read()
row=re.compile(r'(?m)^(\|.*\|)[^|\n]*\|$') if sys.argv[1]=='drop' else re.compile(r'(?m)^(\|.*\|)$')
rep=(lambda m:m.group(1)) if sys.argv[1]=='drop' else \
    (lambda m:m.group(1)+(' 尺寸 |' if '禁止放' in m.group(1) else '---|' if set(m.group(1))<=set('|-') else ' 220 |'))
t=row.sub(rep,s)
if t==s: sys.exit(9)
io.open(p,'w',encoding='utf-8').write(t)
PY
}

CASES=0
# run_case 只看退出码。**warn 不改退出码**，所以一条只报 warn 的检查用 run_case
# 是证明不了的——它挂了和它没挂，退出码一模一样。而「看起来在工作、其实永远返回绿」
# 正是这份测试的由来，加了 warn 档就等于给那个病根开了一个新入口。这一版看输出。
# needle 以 `!` 开头表示「必须**不**出现」——用来钉住「不许喊狼来了」的那一半。


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
# 同一条违规的**另一种写法**。锚在 {6} 上时这条是绿的——量过：三份判据拷贝、
# 体检检查 4、以及判 layout.md 的那条，四处全部只认 6 位，`#fff` 一处都抓不到。
# 2026-08-26 统一放宽到 {3,8}；在 11 份真实产物上量过，零额外命中。
run_case 1 "检查 4 · 三位十六进制（原来的 {6} 锚放过的那种写法）" \
  "printf '\n正文色 #fff。\n' >> design.md"
run_case 1 "检查 5 · 白名单某行没写「禁止放什么」" \
  "sub layout.md '| \`inspector\` | 单对象属性 | 列表、批量动作 |' '| \`inspector\` | 单对象属性 |  |'"
# 检查 5 原来判的是「每行**最后一格**空不空」，下面两种写法量过都是绿的（issue #17）：
# 整列没写时最后一格是「允许放」，永远不空；有第五列尺寸时它判的是尺寸那一格。
run_out 1 "no table in" "检查 5 · 整列「禁止放」都没写（每行只剩两格）" \
  "lastcol drop"
run_out 1 "rows with an empty forbidden cell" "检查 5 · 有第五列尺寸时，空的是中间那格「禁止放」" \
  "lastcol add && sub layout.md '| 列表、批量动作 | 220 |' '|  | 220 |'"
run_out 1 "no table in" "检查 5 · 表头写成非规范的「禁止」（术语表钉的是「禁止放」）" \
  "sub layout.md '| 禁止放 |' '| 禁止 |'"
run_out 1 "rows with an empty forbidden cell" "检查 5 · 用一个破折号占位，等于没写" \
  "sub layout.md '| 列表、批量动作 |' '| — |'"
# 同一条检查不许喊狼来了的那一半：英文表头要认得；空的是尺寸那格不算；
# 别的表里有一行**内容**引用了「禁止放」这个词，不许被当成白名单的表头。
run_case 0 "检查 5 · 英文表头 Must not hold 也认（术语表钉的另一种渲染）" \
  "sub layout.md '| 区域名 | 允许放 | 禁止放 |' '| Region | Must hold | Must not hold |'"
run_case 0 "检查 5 · 第五列尺寸空着不判红（判的是「禁止放」那一列，不是最后一列）" \
  "lastcol add && sub layout.md '| 列表、批量动作 | 220 |' '| 列表、批量动作 |  |'"
run_case 0 "检查 5 · 术语表里有一行写着「禁止放」，不许被当成表头" \
  "printf '\n## 术语\n\n| 英文 | 中文 |\n|---|---|\n| must not hold | 禁止放 |\n| focus slot |  |\n' >> layout.md"
run_case 1 "检查 8 · 一对 surface/-foreground 的对比度低于 design.md 的阈值" \
  "sub src/tokens.css '--card-foreground: #1a1a1a;' '--card-foreground: #f2f2f2;'"
run_case 1 "检查 6 · 白名单里的区域名从没被渲染" \
  "sub src/ui/region.tsx \"  | 'inspector'\" \"  | 'inspector'
  | 'never-rendered-anywhere'\" && sub src/ui/region.tsx '  inspector: {' \"  'never-rendered-anywhere': { label: 'X', desc: '禁止 X。' },
  inspector: {\""

# —— 检查 6 现在是**三档**，上面那条只钉住了中间那档。三档是一个整体，所以放在一起，
# 哪怕其中两条是绿的（同下面 2b 的跨技术栈那组：一个行为一组用例，红绿混排）。
#
#   · $SRC 里一个白名单名字都找不到 → skip。$SRC 是生产树，线框住在工作台、不在里面，
#     所以「规范写完、资产层生成了、功能代码还没开始」的项目就是这个样子。
#   · 找到一部分、缺一部分 → 判红，点名缺的那些。上面那条就是这一档（缺 1、找到 4）。
#   · 全找到 → 绿。
#
# 放宽一档只有一个失败方向：把一条**能失败**的检查变成永远不会响的检查。所以离 skip
# 最近的那一端要单钉——只渲染一个区域、其余四个全缺时必须**仍然**判红。
# 两头都量过，不是读出来的：
#   · 用 HEAD 上的旧模板跑 `rm src/App.tsx`，旧版打
#     「declared but never rendered: app-shell inspector main main.pagehead nav」并 exit 1；
#     新版打 skip 并 exit 0。所以下面两条 skip 用例对旧行为是红的。
#   · 红那条：把检查 6 里的 drift 换成 ok 之后它就绿了——exit 1 只由检查 6 给，
#     不是别的检查顺手给的（就是 9b 那种「红得毫无关系」的病）。
#
# skip 与 drift 钉在**同一句话**上，方向相反：drift 那句被改写时，skip 那条的否定
# needle 会空过，但红那条的肯定 needle 立刻变红。放过的是 skip 那句自己被改写——
# 它只由 exit 0 那一半兜着。
run_out 0 'feature code has not started' \
  "检查 6 · 生产树里一个白名单名字都找不到 → skip，不许判红（功能代码还没开始）" \
  "rm -f src/App.tsx"
run_out 0 '!declared but never rendered' \
  "检查 6 · 同上，整张白名单不许被报成漂移（旧版在这里 exit 1）" \
  "rm -f src/App.tsx"
run_out 1 'declared but never rendered:' \
  "检查 6 · 只渲染一个区域、其余全缺 → 仍然判红（离 skip 最近的那一端）" \
  "printf 'import { Region } from \"./ui/region\"\nexport const App = () => <Region id=\"nav\" />\n' > src/App.tsx"

# —— 检查 2b 的跨技术栈行为。三条都来自 2026-08-25 的 Vue / React Native 实测端口，
# 每一条在改动之前都是**绿的**，而三种失效方向各不相同。
#
# 容器文件是标记唯一该被手写的地方。React 侥幸过关是因为 JSX 写 `data-region={id}`
# 用花括号，而旧模式只认 `="`；Vue 写 `:data-region="id"`，于是资产层自己被判成
# 违反它自己实现的那条规则。
run_case 0 "检查 2b · 容器用 Vue 式绑定写标记 → 不许判红（容器是标记的合法住处）" \
  "sub src/ui/region.tsx 'data-region={id}' ':data-region=\"id\"'"
# `<[a-z]` 编码的是「裸元素是小写的」——那是 DOM 的事实。React Native 里没有小写元素，
# 这个模式在那里一个都匹配不到。
run_case 1 "检查 2b · 大写标签里手写标记（React Native 没有小写元素）" \
  "printf 'export const X = () => <View data-region=\"sidebar\" />\n' > src/Bypass.tsx"
# 标记名不是常量。写死 data-region 时，RN 项目里满屏 testID 也照样报绿。
run_case 1 "检查 2b · MARKER 换成 testID 后认得出 testID 的手写标记" \
  "sub audit.sh 'MARKER=\"data-region\"' 'MARKER=\"testID\"' && printf 'export const X = () => <View testID=\"sidebar\" />\n' > src/Bypass.tsx"

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
run_out 0 'oklch and friends are not read here' \
  "检查 8 · token 全是 oklch 时报 skip，不许打绿勾" \
  "sub src/tokens.css '--card: #ffffff;' '--card: oklch(1 0 0);' && sub src/tokens.css '--card-foreground: #1a1a1a;' '--card-foreground: oklch(0.2 0 0);'"

# 基础对（background / foreground）。它不叫 background-foreground，所以 X/X-foreground
# 那条规则看不见它——而 design.md 的阈值恰恰是**为它**写的（「正文与背景的对比度」）。
# 补上之前：白底白字（1.00:1，最坏的情况）报 "no hex pairs"、"No drift found."、exit 0。
run_case 1 "检查 8 · 基础 background/foreground 对低于阈值（不叫 -foreground 的那一对）" \
  "printf '  --background: #ffffff;\n  --foreground: #ffffff;\n' >> src/tokens.css"
# 对照：同一对达标时不许误报，否则上一条只证明了「这个脚本会红」。
run_case 0 "检查 8 · 基础对达标时不误报（这条检查不许喊狼来了）" \
  "printf '  --background: #ffffff;\n  --foreground: #111111;\n' >> src/tokens.css"
# 容器键不是 token。ui-contract-assets 明确支持 theme.extend / theme object，
# 而原来的取值把 `theme:` `extend:` `colors:` 三个都当成了没声明的 token 报出来。
# token 名以 `--` 开头，不加终止符的话 grep 会把它当成自己的选项：往 stderr 打一屏 usage，
# 然后把每一个都报成「缺失」。**错误答案 + 噪音**，而且在任何按 CSS 写法写声明表的项目上
# 都会发生。夹具原来的声明表写的是裸名（`card`），所以这个洞在夹具里从不触发。
run_out 0 '!declared but not in the token file' \
  "检查 7 · 声明表按 CSS 写法带 -- 前缀时不许误报（grep 把它当选项）" \
  "sub design.md '| \`card\` |' '| \`--card\` |'"
# 命名空间前缀属于**格式**不属于名字：Tailwind v4 的 token 文件写 --color-brand，
# 而声明表说的名字是 brand。按字面比会把整张表和整个 token 文件互报为缺失（实测 10 + 27 条，全假）。
run_out 0 '!in the token file but not declared' \
  "检查 7 · Tailwind v4 的 --color-* 前缀不算改名（格式 ≠ 名字）" \
  "sub src/tokens.css '--card:' '--color-card:'"
# 值写在下一行的声明（长字体栈的常规写法）到达解析器时值是空的，和容器键长得一样，
# 于是被跳过 → 该 token 静默消失 → 检查 7 报「声明了但 token 文件里没有」，
# **答案是错的，而且指向了文档而不是指向这个解析器**。与多行 JSX 调用点同一种形状。
run_out 0 '!declared but not in the token file' \
  "检查 7 · 值换行写的 token 不许被当成容器键漏掉（行式解析的老洞）" \
  "sub design.md '| \`brand\` | this project |' '| \`brand\` | this project |
| \`wrapped\` | this project |' && printf '  --wrapped:\n    a, b, c;\n' >> src/tokens.css"
run_out 0 '!in the token file but not declared' \
  "检查 7 · theme.extend 的容器键不算 token（合法形状不许报假 warn）" \
  "printf 'theme: {\n  extend: {\n    colors: {\n    }\n  }\n}\n' >> src/tokens.css"

# 标记与平台共用时（RN 的 testID 本来就是 e2e 钩子），grep 分不开绕过和测试钩子。
# 这时必须报 skip 并说明理由——旧版在那里打的绿勾，是靠在一个没有 data-region 的
# 平台上找 data-region 找不到而得来的。
run_out 0 'shared with the platform' \
  "检查 2b · 标记与平台共用时报 skip，不许打绿勾" \
  "sub audit.sh 'MARKER_EXCLUSIVE=\"yes\"' 'MARKER_EXCLUSIVE=\"no\"'"
run_out 0 '!every marker goes through the container' \
  "检查 2b · 同上，绿勾那句话不许出现" \
  "sub audit.sh 'MARKER_EXCLUSIVE=\"yes\"' 'MARKER_EXCLUSIVE=\"no\"'"

echo "C. 退出码：没有契约 / 契约在但这次跑没看到它"
# 夹具现在自带一份带 Key 列的 config.md，所以基线本身就在走推导路径。
run_case 2 "没有 layout.md、config 也删掉 → exit 2（真的没东西可检）" \
  "rm -f layout.md docs/ui-contract/config.md"
# 「没东西可检」和「配置说有、这次跑却没看到」必须分开。共用 exit 2 时后者会伪装成前者：
# 输出是一句平静的 "there is no contract to check"，读起来像通过，实际是 setup 没做完。
run_case 3 "路径表说 layout.md，而它不在磁盘上 → exit 3" "rm -f layout.md"
# 反方向才是会**绿着挂**的那个：路径表把规范改了名，根目录还留着一份旧的。
# 旧检测方式是「比较脚本里的常量和表里的值」；现在脚本直接用表里的值，
# 于是这种失效换了形状——表指着的那个名字不在磁盘上。旧 layout.md 还在也不会被误审。
run_case 3 "路径表把规范改了名，旧 layout.md 还在原地 → exit 3（最会假绿的一种）" \
  "sub docs/ui-contract/config.md '| \`layout\` | 结构规范 | \`layout.md\` |' '| \`layout\` | 结构规范 | \`UI-STRUCTURE.md\` |'"
# 空单元 ≠ 用默认值。「没有 config」是合法状态，「config 开了个头没填完」不是——
# 悄悄替换成默认值会去审一个没人选过的路径，而报告读起来完全正常。
run_case 3 "路径表里有 Key 但 Path 是空的 → exit 3（setup 没做完）" \
  "sub docs/ui-contract/config.md '| \`src\` | 生产代码树 | \`src\` |' '| \`src\` | 生产代码树 |  |'"
# 同一个键上，「行在、单元空」和「整行不在」只差一行的存在与否，结论却相反。上面那条钉
# 的是前者（src），这条钉同一档的 workbench——单钉它，是因为 workbench 恰好是刚开了
# 「整行不在就用默认值」这条宽的那个键。宽只许开在「没有这一行」上，不许顺手把空单元
# 也放过去。量过：把 BLANK 那个 abort 改成 `if false`，这处注入就 exit 0——
# exit 3 只由它给，不是别的地方顺手给的。
run_out 3 'empty Path cells for: workbench' \
  "workbench 行在、Path 单元是空的 → 仍然 exit 3（宽只开给「整行不在」）" \
  "sub docs/ui-contract/config.md '| \`workbench\` | 工作台 | \`.ui-contract-local\` |' '| \`workbench\` | 工作台 |  |'"
# 整行不在，是**旧 config**，不是没填完的 setup——和「没有 Key 列」是同一件事，只是少
# 一行而不是少一列。workbench 是最近才进表的那一行，所以「早于这次改动的项目」不是假设：
# 用 HEAD 上的旧模板跑同一处注入量过，旧版打的是「has empty Path cells for: workbench」
# 并 exit 3，一条检查都没跑就死了——一句关于一个**根本不存在的单元**的话，正是这份脚本
# 存在的那种「自信的错答案」。
NO_WORKBENCH_ROW="sub docs/ui-contract/config.md '| \`workbench\` | 工作台 | \`.ui-contract-local\` | 仓库根，不提交 |
' ''"
# 锚在那句黄字横幅上，连键名一起。**exit 0 才是这条的重点**：横幅是在两个 abort
# **之前**打的，所以横幅出现证明不了这一轮真的跑完了，证明它的是退出码。
run_out 0 'has no row for: workbench' \
  "路径表里没有 workbench 这一行 → 降级成默认值并点名，不是 exit 3（旧 config）" \
  "$NO_WORKBENCH_ROW"
# 另一半：旧版那句事实错误的话不许回来。表里没有那个单元，却报「空单元」——
# 这种话一旦重新出现，退出码可能还是 0（只要 abort 被挪走），单看退出码看不出来。
run_out 0 '!empty Path cells' \
  "同上，那句关于「空单元」的话不许出现（表里根本没有那个单元）" \
  "$NO_WORKBENCH_ROW"
# 存量 config 没有 Key 列。那不是「没填完」，是**旧格式**——按 exit 3 处理会让所有
# 早于这次改动的项目一律报红。降级成默认值 + 明说，而不是报错。
run_out 0 'no Key column' "旧格式 config（无 Key 列）→ 用默认值并说明，不是 exit 3" \
  "printf '| 结构规范 | \`layout.md\` | \`layout.md\` at the repo root |\n' > docs/ui-contract/config.md"
run_out 0 'defaults' "完全没有 config → 用默认值并说明" "rm -f docs/ui-contract/config.md"
# 上面四条只钉住了 layout 与 src 两行。exit 3 的那句话说的是「表里指着的路径不在磁盘上」，
# 是个全称，而循环一度只查三条派生路径——漏掉的两条恰好是失效得最难看的两条，
# 且**两种失效的形状相反**，所以分开各钉一条：
#
#   · design 过期 → 检查 4 降级成一行黄色 skip，整轮还能 exit 0（**安静地少判**）
#   · tokens 过期 → 检查 3 把 token 文件自己的色值报成硬编码漂移（**自信的错答案**）
#
# 第二条尤其要留着：它和 audit.sh 头部拿来论证「砍掉 6 个路径旋钮」的症状是同一个。
# 旋钮搬进路径表只是换了错路径的来源，没有让错路径不再产出那份报告。
run_case 3 "路径表把 design.md 改了名 → exit 3（否则检查 4 静默降级成 skip）" \
  "sub docs/ui-contract/config.md '| \`design\` | 视觉规范 | \`design.md\` |' '| \`design\` | 视觉规范 | \`docs/visual-spec.md\` |'"
run_out 3 'TOKENS=' "路径表把 token 文件改了名 → exit 3（否则检查 3 把 token 文件自己报成漂移）" \
  "sub docs/ui-contract/config.md '| \`tokens\` | Token 文件 | \`src/tokens.css\` |' '| \`tokens\` | Token 文件 | \`src/theme/tokens.css\` |'"
# 反方向的宽必须同时钉住，否则上面两条会诱使人把 none yet 也判成 exit 3——
# 而「这个项目还没有视觉规范」是合法状态，不是没填完的 setup。
run_out 0 '!TOKENS=' "design 写 none yet → 不是 exit 3（还没写视觉规范是合法状态）" \
  "rm -f design.md && sub docs/ui-contract/config.md '| \`design\` | 视觉规范 | \`design.md\` |' '| \`design\` | 视觉规范 | none yet |'"

echo "D. 检查 9 · 工作台不许被提交，也不许住着权威"
# 夹具刻意没有工作台目录，所以 9a 在基线上报 skip。**这个 skip 本身要被钉住**：
# 它是这条检查唯一的宽，而「没建过线框」和「建了但忘了 ignore」在输出里只差一个词。
run_case 0 "9a · 没有工作台目录时报 skip，不许判红（噪音落在正确的仓库上就没人读了）" "true"
run_out 0 "not on disk" "9a · 同上，skip 那句话必须说清是「磁盘上没有」而不是「通过了」" "true"
run_case 1 "9a · 工作台在磁盘上，但根本没有 .gitignore（整个被提交）" \
  "mkdir -p .ui-contract-local/wireframe"
run_case 1 "9a · 有 .gitignore，但没写工作台那一行（最容易发生的一种）" \
  "mkdir -p .ui-contract-local/wireframe && printf 'node_modules\ndist\n' > .gitignore"
# 注释掉的那一行是真会出现的写法，而 `grep -q .ui-contract-local` 会被它骗过去。
run_case 1 "9a · 工作台那一行被注释掉了（子串匹配会放它过去）" \
  "mkdir -p .ui-contract-local/wireframe && printf 'node_modules\n# .ui-contract-local/\n' > .gitignore"
run_case 0 "9a · 正确 ignore 时不误报（这条检查不许喊狼来了）" \
  "mkdir -p .ui-contract-local/wireframe && printf 'node_modules\n.ui-contract-local/\n' > .gitignore"
# 9b 才是值钱的那半：token 文件是值权威，落进一个永不提交的目录里，
# 别人 clone 到的是一份值指向空处的规范。
# **注入形状变了**：TOKENS 不再是脚本里的常量，它从路径表推导——所以注入路径表，
# 那也更接近真实失效（真实项目里没人改脚本常量，是 setup 把行填错了）。
#
# **注入必须把文件也搬过去，不能只改路径表。** 理由和下面 `none yet` 那条一样：
# 只改表的话，表指着的那个路径在磁盘上不存在，于是 exit 3（「配置指着的路径不在磁盘上」）
# 先于 9b 命中，这条用例就在测另一件事了。而真实的 9b 失效里那个文件是**存在**的——
# admin-console 当初的 `wireframe/src/index.css` 就真的躺在那儿——所以搬文件才是那个形状。
#
# **这条只能用 run_out，不能用 run_case。** 原来这里并排放着一条只看退出码的
# `run_case 1`，而它是死的：量过——把检查 9b 整段摘掉，它照样绿。token 文件一旦离开
# 生产树，检查 3 的排除项（`grep -v "^$TOKENS:"`）就不再排除它、检查 7 也对不上账，
# 退出码由那些无关的检查决定，9b 在不在都一样。这正是本文件开头说的那种病，
# 只是长在测试自己身上。**分开红与红的唯一办法是看那句话**，所以只留 run_out。
TO_WORKBENCH="mkdir -p .ui-contract-local/wireframe/src && mv src/tokens.css .ui-contract-local/wireframe/src/index.css && sub docs/ui-contract/config.md '| \`tokens\` | Token 文件 | \`src/tokens.css\` |' '| \`tokens\` | Token 文件 | \`.ui-contract-local/wireframe/src/index.css\` |'"
run_out 1 "value authority" "9b · 路径表把 token 文件填进了工作台，报错必须说清它是值权威" "$TO_WORKBENCH"

# ── 9c · 资产层同时存在于两处 ────────────────────────────────────────────────
# 2026-08-28 新增。这条守的失败**只在本地发生**：资产层迁进生产树之后没人清
# `asset-staged`，工作台里留下一份拷贝——而工作台永不提交，所以它不进 diff、不进
# review，只在本地跟生产树那份分叉，而重建投影时可能消费它。
#
# 夹具的基线正好是「已迁入、旧配置没有这一行」，所以三条用例合起来钉住三种状态：
# 没有这一行 → skip；有行但没目录 → 不许红（陈旧的格子不是漂移）；两处都在 → 红。
# 中间那条是这里最值钱的：少了它，下一个人会把判断从「两份都在盘上」改成「格子填了」，
# 那样每一个迁完忘了清格子的正确仓库都会被判红，而那正是本仓库栽过的那种门。
# `$STAGE_ROW` 以 heredoc 的结束符收尾，所以**任何要和它并列的命令都得排在它前面**——
# 接在后面会让那一行不再是合法结束符，heredoc 会把后续整段吞掉。第一次写就是这么挂的。
STAGE_ROW='python3 - <<PY
import io
p="docs/ui-contract/config.md"
s=io.open(p,encoding="utf-8").read()
s=s.replace("| \`asset-container\`", "| \`asset-staged\` | 资产层（暂驻） | .ui-contract-local/assets | 工作台内 |\n| \`asset-container\`",1)
io.open(p,"w",encoding="utf-8").write(s)
PY'
run_out 1 "exists twice" \
  "9c · 迁入之后工作台里还留着一份资产层 → 判红（本地分叉，永不进 diff）" \
  "mkdir -p .ui-contract-local/assets && cp src/ui/region.tsx .ui-contract-local/assets/ && $STAGE_ROW"
run_out 0 '!exists twice' \
  "9c · 格子还填着但那个目录已经没了 → 不许红（陈旧的格子不是第二份拷贝）" \
  "$STAGE_ROW"
run_out 0 "nothing staged" \
  "9c · 配置里根本没有这一行（今天之前写的每一份都是）→ skip，且不许报成猜测路径" \
  "true"
# `none yet` 是路径表里的合法值，不是路径。当成路径去比会得到一句莫名其妙的绿勾。
# 注入要连夹具的 token 文件一起删掉：只改路径表的话，那个文件不再被检查 3 排除，
# 于是退出码被一条无关的检查决定，这条用例就不再测它自称在测的东西。
run_out 0 "no token file yet" "9b · 路径表写着 none yet 时报 skip（那不是一个路径）" \
  "rm -f src/tokens.css && sub docs/ui-contract/config.md '| \`tokens\` | Token 文件 | \`src/tokens.css\` |' '| \`tokens\` | Token 文件 | none yet |'"

# workbench 的 none yet 分支要单独钉：它刚从**死代码**里救活。原来那个 `[ -z "$WORKBENCH" ]`
# 永远进不去（derive 要么给默认值、要么在上游 exit 3），所以它写错了也没人知道。
# 上面那条 9b 走的是 tokens 行，碰不到这一段——一条用例覆盖不了另一行的同名值。
# 判据取报错里那句话，不取退出码：这一档是 skip，退出码证明不了它进没进这个分支。
run_out 0 'names no workbench' "9a · workbench 写 none yet 时报 skip（占位符不是目录名）" \
  "sub docs/ui-contract/config.md '| \`workbench\` | 工作台 | \`.ui-contract-local\` |' '| \`workbench\` | 工作台 | none yet |'"

echo "E. 检查 10 · 结构参数还在等视觉刻度"
# 这条是 warn 档：退出码证明不了它，只能证明它**不**改退出码。所以两条都看输出。
# 「不许喊狼来了」那一半单列，因为 warn 计数一旦虚高，最后那句 warning(s) 就没人读了。
run_out 0 "still marked" "10 · layout.md 里有未结清的 ⏳ → warn 并列出来（退出码不变）" \
  "printf '\n| 面板宽 | 360 | ⏳ 等字号刻度 |\n' >> layout.md"
run_out 0 "!still marked" "10 · 没有 ⏳ 时不许报 warn（这条检查不许喊狼来了）" "true"
# 交接单必须**逐字**带上那几行，不能改写——改写等于这个脚本在替别人发明需求，
# 而这份提示词是唯一会送到视觉那一侧的东西（同 ADR-0007 对提示词的要求）。
run_out 0 "⏳ 等字号刻度" "10 · 提示词逐字带上 ⏳ 那一行（不许改写成自己的话）" \
  "printf '\n| 面板宽 | 360 | ⏳ 等字号刻度 |\n' >> layout.md"
run_out 0 "copy from here" "10 · 输出的是可以整段拷走的交接单，不是一句提醒" \
  "printf '\n| 面板宽 | 360 | ⏳ 等字号刻度 |\n' >> layout.md"
run_out 0 "!copy from here" "10 · 没有 ⏳ 时不许打印交接单" "true"
# 实测出来的：解释 ⏳ 约定的那几句散文自己也含这个字符。第一版锚在字符上，
# 一份只有 3 个待定数字的文档被报成 6 个，交接单里带出三段关于它自己的话。
# **一个没人敢信的计数比没有计数更糟**，何况这份提示词是唯一会送到视觉那侧的东西。
run_out 0 "!copy from here" "10 · 散文里提到 ⏳ 不算一个待定数字（锚在表格行，不在字符）" \
  "printf '\n关于 ⏳ 的约定：它表示这个数还在等视觉刻度。\n' >> layout.md"

# ⛔ 的三条。check 10 曾只数 ⏳，被驳回的方向（⛔）对体检不可见——缺口写在三个
# 文件的例外注记里，交接靠人工点名。机制补上后，这几条钉住三件事：报得出、
# 不混进 ⏳、散文里的 ⛔ 不算（与 ⏳ 同锚：表格行）。退出码不变是故意的：
# ⛔ 和 ⏳ 同属 warn 层——挂掉构建只会鼓励人删标记，而不是回答它。
run_out 0 "refuted structural direction" "10 · ⛔ 表行报为 refuted（warn 层，退出码不变）" \
  "printf '\n| 面板宽 | ~~360~~ | ⛔ 被投影驳回：9 字段 + 5 动作在任何字号下都放不进 360 |\n' >> layout.md"
run_out 0 "!still marked" "10 · ⛔ 不许混进待定 ⏳ 的计数（死问题不是开放问题）" \
  "printf '\n| 面板宽 | ~~360~~ | ⛔ 被投影驳回：9 字段 + 5 动作在任何字号下都放不进 360 |\n' >> layout.md"
run_out 0 "!refuted structural direction" "10 · ⛔ 写在散文里不算（与 ⏳ 同锚：表格行）" \
  "printf '\n这个方向被驳回了：⛔ 换一种布局。\n' >> layout.md"

# JSON 尾注的三条。散文报告与退出码不动，尾注是给自动化调用方的；
# 「哪些检查静默跳过」从此是字段，不是语气。
run_out 0 'AUDIT-JSON' "尾注 · 每次运行都带机器可读汇总（干净夹具全 pass）" "true"
run_out 1 '"3":"fail"' "尾注 · 注入检查 3 违规后，尾注把 3 标为 fail" \
  "printf '.card { background: #123456; }\n' > src/feature.css"
# rm design.md 走 exit 3 早退，不带尾注——skip 用例用检查 8 的 oklch 降级路径。
run_out 0 '"8":"skip"' "尾注 · 检查 8 的 oklch 降级路径记 skip，不是静默绿" \
  "sub src/tokens.css '--card: #ffffff;' '--card: oklch(1 0 0);' && sub src/tokens.css '--card-foreground: #1a1a1a;' '--card-foreground: oklch(0.2 0 0);'"


printf '\n'
[ $FAIL -eq 0 ] && printf '  \033[32m%s 个用例全部符合预期（%s）\033[0m\n' "$CASES" "$(basename "$SH")" \
                || printf '  \033[31m有检查名存实亡\033[0m\n'
exit $FAIL

