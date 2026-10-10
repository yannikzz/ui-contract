# ui-contract · 界面契约 · {{VERSION}}

团队有设计系统（颜色、字体、间距），却没有任何东西回答「**新功能该放在界面哪里**」。于是每个新功能都落在上一个人（或上一个 AI）随手放的位置，半年后界面结构就乱了。

这套技能通过访谈帮你把这条规矩立起来，并让写代码的 AI 也遵守它。

## 它会产出什么

| 产物 | 是什么 |
|---|---|
| `layout.md` | 结构规范：一棵「新功能放哪」的决策树，加一张区域白名单。每个区域都写明**允许放**什么、**禁止放**什么 |
| `design.md` | 视觉规范：只写规则，具体数值放在 token 文件里 |
| 资产层 | 进生产代码的区域类型和容器组件。写了白名单之外的区域名，类型检查直接报错 |
| 低保真线框 | 能跑起来的界面骨架，刻意不带品牌色，免得被当成视觉标准照抄 |
| 强制与体检 | 让 AI 改代码时先查规范；几个月后再跑一次体检脚本，看代码和规范有没有走样 |

## 安装（两种方式选一种，不要两种都装）

### A · Claude Code（推荐）

1. 把压缩包解压到一个**固定的位置**，例如 `~/tools/ui-contract`。安装之后，这个文件夹就是插件的来源，不要删除或移动它。
2. 在终端里执行（把路径换成你解压的位置）：

   ```bash
   claude plugin marketplace add ~/tools/ui-contract
   claude plugin install ui-contract@yannikzz
   ```

   也可以在 Claude Code 对话框里输入 `/plugin marketplace add ~/tools/ui-contract`，再输入 `/plugin install ui-contract@yannikzz`。
3. 新开一个 Claude Code 会话，就能用了。

### B · 其他 AI 编程工具（Cursor、Codex、Windsurf、Cline 等）

进入解压后的文件夹，运行安装脚本，它会把 `skills/` 下的全部技能复制到你的工具读取技能的位置：

```bash
cd ~/tools/ui-contract
./install.sh windsurf          # 装到当前项目的 .windsurf/skills/
./install.sh cline             # 装到当前项目的 .cline/skills/
./install.sh 你的工具的技能目录   # 其他工具：先查它的文档，看技能放在哪里
```

不带参数运行 `./install.sh` 会装到 `~/.claude/skills/`，这是 Claude Code 的个人技能目录。用 Claude Code 的话，请改用上面的方式 A。

Windows 上没有 `sh` 时，可以手动把 `skills/` 里的**全部**文件夹复制到工具的技能目录。

**一定要全部安装。** 这 15 个技能之间会互相调用，只装一部分时不会报错，但整套流程会悄悄断掉。

> 有一点限制：「白名单变成类型」这一层依赖 TypeScript 类型检查。如果你的工具不能执行类型检查，四层强制只能用上三层。技能自己会说明这一点。

## 怎么用

不需要记命令，直接描述你遇到的问题，技能会自己启动：

- 「每次加新功能都乱放，我想立个规矩」
- 「把这几张 Figma 截图变成开发能照着做的规范」
- 「别让 AI 每次改前端都把结构改乱」
- 「三个月前写的规范还管用吗？」（会直接进入体检）

它会**一次只问一个问题**，每个问题都附上推荐选项和这个选项的代价。你的技术栈、已有文档这类事实，它会自己去查，只把真正需要你决定的事情交给你。

你可以从任何一步开始。比如已经有 `layout.md`、只想加强制，就直接说这件事。每一步都从磁盘读取上一步的产物，不会重复问已经回答过的问题。

## 更新到新版本

拿到新的压缩包后：

1. 解压，**覆盖**原来的文件夹（位置和以前一样）
2. 执行：

   ```bash
   claude plugin marketplace update yannikzz
   claude plugin update ui-contract@yannikzz
   ```

用方式 B 安装的话，重新运行一遍 `./install.sh`（参数和上次一样）。它会列出已经装过的技能，问你是否替换，输入 `y` 回车即可。

## 卸载

```bash
claude plugin uninstall ui-contract@yannikzz
claude plugin marketplace remove yannikzz
```

用方式 B 安装的话，到技能目录里删掉这 15 个文件夹即可。

## 许可证

MIT，见同目录下的 `LICENSE`。版权归 yannikzz 和 loot20mal（GitHub 账号）。
