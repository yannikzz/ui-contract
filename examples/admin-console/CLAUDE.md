# CLAUDE.md

## UI 契约（改任何界面之前先读这一段）

本项目的界面结构由 **`layout.md`** 约束，视觉由 **`design.md`** 约束。切线只有一条：**换品牌视觉时会不会变**——会变的归 `design.md`，不会变的归 `layout.md`。两份零重叠，同一个数值只住一个地方。

### 硬规则

1. **改任何界面结构之前，先走 `layout.md` §1 落位决策树。** 走通了直接实现，不用改文档。
2. **走不通就停下。** 不许自己新开一个区域、一栏、一个浮层、一个页型，也不许「先挑个最像的区域放着」。按 `layout.md` §9.3 写区域申请，回答那五问。**五问答不出来，说明需求本身没想清楚，不是布局问题。**
3. **代码里每个区域的标记必须出现在 `layout.md` §2 白名单里。** 不在表里的名字就是违规。
4. **新增区域的顺序写死**：改 `layout.md` §2 → 改 `src/ui/region.tsx` 的 `RegionId` 与 `REGION_META` → 写代码。**顺序不能反。**
5. **文档与代码冲突时改代码。** 已有代码不是权威。
6. 推翻旧结论时**不要删**，移到 `layout.md` 附录 B 并写清理由。被推翻的判断比现行判断更容易重复踩坑。

### 任务听起来很小的时候也适用

「只是加个按钮」「只是在表格里加一列」「只是在侧边放个说明」——这三个恰好是最常违反规范的改动。规则不因为改动小而豁免。

### 最容易被违反的四条（完整清单见 `layout.md` §10）

| 别做 | 因为 | 改成 |
|---|---|---|
| 在表格行尾加操作按钮列 / 「更多」菜单 | 无底洞，且操作会有两个宿主、两边逻辑会漂 | 点行 → `inspector.foot`。列型枚举里没有 `actions`，写不出来 |
| 往筛选条里放导出 / 新建 / 批量删除 | 筛选条的承诺是「只改变我看到哪些」，混入动作后用户不敢点 | 页级 → `main.pagehead`；批量 → `main.bulkbar` |
| 给向导页加侧边帮助面板 | 会一路长成「带侧栏的工作台」 | `overlay` 临时查看。`PageWithInspector` 类型直接拦住 |
| 新建一条跨栏顶栏放「暂时不知道放哪」的东西 | 跨栏栏是拓展黑洞，半年后会是一条 12 个图标的杂物栏 | 走决策树；真需要走 §9 |

## 文件

| 文件 | 管什么 | 什么时候读 |
|---|---|---|
| `layout.md` | 结构：区域树、栏宽、页型、拓展位、内容落位、降级 | 加功能、挪位置、新增页面 |
| `design.md` | 视觉：颜色、字号、间距、圆角、状态样式、组件变体 | 调样式、加组件 |
| `src/ui/region.tsx` | **资产层**：区域白名单的类型形态 + 结构容器。生产代码，业务从这里 import | 新增区域、写任何带区域标记的代码 |
| `.ui-contract-local/wireframe/` | 上面两份的可运行参考实现（低保真、刻意无品牌视觉）。**一次性**，消费资产层 | 想知道「这块到底摆在哪」时 |
| `.ui-contract-local/wireframe/CLAUDE.md` | 线框目录的硬约束 + **刻意的取舍清单** | 动 `.ui-contract-local/wireframe/` 里任何代码之前 |
| `docs/ui-contract/adr/layout/` | **决策记录**：每条重量级结构决策**为什么这么定、排除了什么、什么条件下复议**。只指向 `layout.md` 的条款，不复述条款 | 你觉得某条规则不合理时——先看有没有一份记录已经排除过你想提的方案 |
| `docs/ui-contract/config.md` | 授权、文件位置、以及**本轮未验证的事项** | 想知道某个结论有没有证据支撑时 |

## 编译期校验

区域白名单在 `src/ui/region.tsx`（资产层，**在线框目录之外**）里是 TypeScript 联合类型。写一个不在表里的区域名会**直接类型报错**。展示层 `.ui-contract-local/wireframe/src/wire.tsx` 只把这个类型转发出去，**白名单只有这一份**。

```bash
pnpm typecheck
```

同类手法还用在别处，而且**同样住资产层**：`TableColumnKind` 里没有 `actions`、`PageWithInspector` 里只有 `'list'`、`InspectorKind` 里只有 `'content-item'`——**这些缺失都是刻意的**。看到「好像漏了一个」时先读 `layout.md` 对应小节，再决定是不是真要加。

它们曾经声明在线框里。那样只约束得住线框——而线框是一次性的，**产品代码照样可以做被禁止的事，没有任何东西会响**。规则约束的是会发布的代码，所以类型必须和产品代码一起过类型检查。

### 禁令是**双向**守住的

省略只在一个方向上被强制：编译器抓「代码用了禁止的成员」，没有任何东西抓「有人把成员加回来」。加回来的那一刻所有调用点照样编译，注释开始描述一条已经不存在的规则，而**输出一模一样**。

`src/ui-contract.assert.ts` 补的就是另一个方向：每条禁令一行 `@ts-expect-error`，禁令还在时它消费掉那个错误；**谁把禁止的成员加回去，指令就变成未使用，tsc 报 TS2578**。实测过：往 `TableColumnKind` 里加回 `'actions'` → `src/ui-contract.assert.ts(24,1): error TS2578`。

那个文件没有任何人 import，**靠 tsconfig 的 `include` 覆盖到它**。改 `include` 时别把它漏掉——漏掉之后它和一个通过了的文件在输出里完全一样。

## 工作台：`.ui-contract-local/`

两个维度的**排练**住这里：线框（`layout` 维度）、旋钮记录与皮肤改动（`design` 维度）。两个维度的**权威**住仓库：`layout.md`、`design.md`、**token 文件 `src/tokens.css`**、`docs/ui-contract/`。

**一个真实项目会把 `.ui-contract-local/` 加进 `.gitignore`。本项目刻意没有**——它是 ui-contract 的示例，存在的目的是被读，理由写在 `.gitignore` 里和 `examples/README.md`。

线框不在仓库里时怎么重建：跑 `ui-contract-wireframe` 技能，输入是 `layout.md`、`design.md` 和 `src/ui/region.tsx`——三个都是提交的。

```bash
pnpm typecheck       # 白名单 + 禁令自断言
pnpm check-colours   # 线框颜色纪律。**不是 CI 层**，见脚本头部
pnpm build           # typecheck + vite build。check-colours 不在里面，见 examples/README.md「Verified」
```
