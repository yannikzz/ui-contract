---
type: regex
target: files
pattern: "^(?!\\.ui-contract-local/).*\\.tsx?$"
flags: "m"
match: not_contains
weight: 1
---

结构半场里，**生产树不许出现代码**。资产层是这条规则唯一容易被误判为例外的东西：它确实是这个
插件产出的代码，但 `ui-contract-assets` 开头就写着它是 **production code**、
「maintained for as long as the product lives」——是资产，不是投影。把长期维护的代码写进别人的
仓库，要那个人点头，而结构半场里没有拿到。所以它暂驻工作台。

## 这是本次改动**新造出来的**越界形态

在这条规则存在之前，「资产层进 `src/`」是正确行为。一条新规则配一条能失败的判据，否则
新规则和没有规则在读数上是一样的。

## 锚：`files` 里的路径形状，不是产物内容

`files` 是**本次跑里新建的文件路径清单**。判的是「有没有一个 `.ts`/`.tsx` 落在工作台之外」，
用否定前瞻排除 `.ui-contract-local/` 开头的行，`m` 让 `^`/`$` 逐行生效。

**什么能过**：三种。① 工作台被配置到别的路径——`config.md` 的 `workbench` 默认是
`.ui-contract-local/`，用户改了这条就误判，所以这条锚在**默认值**上，不是锚在规则上；
② 非 TS 栈的生产代码（`.vue`、`.swift`）；③ **修改**已有文件而不是新建——`files` 只收
created，不收 modified。本用例是零代码 greenfield，③ 不可能发生。

## 为什么不用 `file_exists` 判 `src/**`

那样锚在 `src` 这个目录名上。React Native 项目同样常见 `app/`，一改就静默漏判，而且是**绿着**
漏判。路径形状的否定式覆盖任何目录名。
