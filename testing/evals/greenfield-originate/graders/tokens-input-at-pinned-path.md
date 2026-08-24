---
type: file_exists
path: docs/ui-contract/tokens.input.json
weight: 1
---

`tokens.input.json` 必须落在**钉死的那个位置**：`docs/ui-contract/tokens.input.json`。

ADR-0009 把它从 `config.md` 的可配置路径表里豁免出来——它不是规范而是工作记录，
和 `config.md` 同一个抽屉。豁免的理由是**下游要一个答案而不是一个记录**：
`ui-contract-assets` 要读它把值落进 token 文件，`no-framework-default-values` 那条
regex 判据的 `target.path` 不是 glob、也必须指向一个确定路径。

## 为什么单独一条，而不是把 `tokens-input-written` 改严

因为「没写」和「写错地方」是两个不同的产品缺陷，合成一条就分不开了——
而分不开这两件事，正是 2026-08-22 两轮实跑（约 $6.2）买到的那个教训本身。
和 `tokens-input-written` 配套读，见那一条里的三态表。

⚠ **这条判据在 2026-08-22 那两轮实跑里不存在，落点也还没钉。** 那两轮量到的分布是
三次里两次 `docs/ui-contract/`、一次仓库根——**在钉死之前**。
钉死这件事本身（`originate.md` §The output lands as `tokens.input.json`，
以及 `ui-contract-assets` 前置门里的对应位置）**一次实跑都没跑过**，
这条判据就是去量它的。第一次跑之前，不要把「已钉死」当成「已生效」。

UNVERIFIED：正负两个方向都没有量过。
- 负方向**有旧样本可参照但不算数**：钉死前那次写在仓库根的 run 会让这条红——
  但那是另一版产品，不能拿来当这条判据的验证。
- 正方向要等下一次 `greenfield-originate` 实跑。
- 与 `tool_used` 一类不同，这条**能**用冻结产物做夹具（`file_exists` 只看磁盘），
  但夹具验的是「glob 会不会匹配」，不是「产品会不会写到那里」——和
  `no-framework-default-values` 同一个理由，所以没做。
