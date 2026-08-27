# UI 契约 — 配置

夹具用的最小 config：只有路径表，且带 Key 列（体检脚本按键找行）。

## 路径（权威）

| Key | 产物 | 路径 | 默认值 |
|---|---|---|---|
| `layout` | 结构规范 | `layout.md` | `layout.md` at the repo root |
| `design` | 视觉规范 | `design.md` | `design.md` at the repo root |
| `tokens` | Token 文件 | `src/tokens.css` | 项目已有的 token 源 |
| `tokens-format` | Token 文件格式 | CSS 自定义属性 | — |
| `src` | 生产代码树 | `src` | 产品自己的 UI 代码住哪 |
| `asset-layer` | 资产层 | `src/ui/region.tsx` | 生产代码树内部 |
| `asset-container` | 资产层容器（仅当独立成文件） | | React 下留空 |
| `workbench` | 工作台 | `.ui-contract-local` | 仓库根，不提交 |
| `wireframe` | 线框 | `.ui-contract-local/wireframe` | 工作台内部 |
| `as-built` | As-built 记录 | 不适用 | `as-built.md` |
