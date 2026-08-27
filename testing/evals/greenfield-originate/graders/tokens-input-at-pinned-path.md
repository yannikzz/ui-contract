---
type: file_exists
path: .ui-contract-local/tokens.input.json
weight: 1
---

`tokens.input.json` 必须落在**钉死的那个位置**：`.ui-contract-local/tokens.input.json`。

它不是规范而是工作记录——调色器具的起始状态——所以住在工作台里，跟着工作台一起不提交。
钉死而非可配置的理由是**下游要一个答案而不是一个记录**：器具要找到它，
`no-framework-default-values` 那条 regex 判据的 `target.path` 不是 glob、也必须指向一个确定路径。

⚠ **落点 2026-08-25 从 `docs/ui-contract/tokens.input.json` 改到了这里**，同时
`ui-contract-assets` 不再读它——`originate` 现在直接写 token 文件，那一跳被去掉了
（旧链路实测五次里只落地两次）。

**新落点已经有实跑背书（2026-08-25 网关 3，$19.63）**：`greenfield-originate` 的
run 3/3 拿到 `.ui-contract-local/tokens.input.json exists as expected`，同一次 run 里
`naming-declared` / `no-framework-default-values` / `no-literal-values-in-design` 也全绿——
整条链在改落点之后端到端通了。

⚠ 但那一轮三次里只有这一次干净：另外两次一次 API 掉线、一次无报错空产出（$2.02，
design 技能调用过，产物为空，没有保留沙箱所以查不到原因）。**这个 case 历史上一直很吵**
（0.00 / 0.33 / 0.94 / 0.48 / 0.67 / 0.71 / 0.83），本次 0.33 落在带内。
所以这条判据的正方向**结清了**，而「产品在这条链上稳不稳」**没有**。

## 为什么单独一条，而不是把 `tokens-input-written` 改严

因为「没写」和「写错地方」是两个不同的产品缺陷，合成一条就分不开了——
而分不开这两件事，正是 2026-08-22 两轮实跑（约 $6.2）买到的那个教训本身。
和 `tokens-input-written` 配套读，见那一条里的三态表。

⚠ **这条判据在 2026-08-22 那两轮实跑里不存在，落点也还没钉。** 那两轮量到的分布是
三次里两次 `docs/ui-contract/`、一次仓库根——**在钉死之前**。
钉死这件事本身（`originate.md` §The output lands as `tokens.input.json`，
以及 `ui-contract-assets` 前置门里的对应位置）**一次实跑都没跑过**，
这条判据就是去量它的。第一次跑之前，不要把「已钉死」当成「已生效」。

VERIFIED 2026-08-24/25，**正方向结清**。

第一次实跑（`timeout_seconds: 900`）三次里两次撞墙、一次被中断，产物全被砍断——
量到的是「被砍之前写完了什么」。抬到 1800 之后重跑，**两次干净 run 都是绿的**，
且落点在沙箱里核对过，不是读判据行：两次都是 `docs/ui-contract/tokens.input.json`。
第三次 run 是 `API Error: Connection lost mid-response`，agent 一个字没写出来，
不构成反证。

连同钉死之前那轮（三次里一次落在仓库根），**钉死之后 0/5 跑偏**。

负方向仍然没有干净样本：
- 钉死前那次写在仓库根的 run 会让这条红——但那是另一版产品，不算这条判据的验证。
- 两次「文件不存在」的红（900 秒超时那次、连接中断那次）证明了这条**能**红，
  但红的原因是「根本没写」，不是「写错地方」——那一维仍然没被量到。
  它和 `tokens-input-written` 的区别正在这里，见那一条的三态表。
- 与 `tool_used` 一类不同，这条**能**用冻结产物做夹具（`file_exists` 只看磁盘），
  但夹具验的是「glob 会不会匹配」，不是「产品会不会写到那里」——和
  `no-framework-default-values` 同一个理由，所以没做。
