# 技术栈探针

ADR-0001 决定 A 挂着一条复议条件：

> 若资产层难以适配 React 之外的技术栈，退回 A′（token 只是文档文字，生产代码另写）并承认人肉翻译。

这两个目录是**去撞那条条件的实验**，不是示例产物（那是 `examples/`），也不是夹具（那是
`testing/structure/fixtures/`）。它们存在的唯一理由是：让「资产层能跨栈」这句话可以被**重跑验证**，
而不是只能读一句转述。

`node_modules` 与 lockfile **刻意不进仓库**。装依赖是重跑的一部分，命令写在下面。

## 怎么重跑

```sh
cd testing/stack-probes/vue
npm i && npx vue-tsc --noEmit -p tsconfig.json        # 期望 exit 0

cd ../react-native
npm i && npx tsc -p tsconfig.json                     # 期望 exit 0
```

再各自造一次违规，**期望转红**：

```sh
# Vue
printf '<script setup lang="ts">\nimport Region from "../ui/Region.vue"\n</script>\n\n<template>\n  <Region id="sidebar" />\n</template>\n' > src/pages/Bad.vue
npx vue-tsc --noEmit -p tsconfig.json

# React Native
printf 'import { Region } from "../ui/Region"\nexport function Bad(){ return <Region id="sidebar" /> }\n' > src/screens/Bad.tsx
npx tsc -p tsconfig.json
```

## 2026-08-28 重跑

ADR-0013 改了资产层的落点（迁进生产树之前先暂驻工作台）、给它加了消费 token 文件的第二趟，
并把移植材料拆进了 `ui-contract-assets/porting.md`——**动的正是这两个探针守的那一块**，
所以重跑一次，而不是继续引用三天前的读数。

| | 检查器 | 合法用法 | 白名单外的区域名 |
|---|---|---|---|
| Vue 3 SFC | `vue-tsc` | **exit 0** | **exit 2** · `src/pages/Bad.vue(6,11): error TS2322: Type '"sidebar"' is not assignable to type 'RegionId'` |
| React Native | `tsc` | **exit 0** | **exit 2** · `src/screens/Bad.tsx(2,39): error TS2322: Type '"sidebar"' is not assignable to type '"app-shell" \| "title-row" \| …'` |

两边**双向都验了**，且注入的违规删掉之后各自复原到 exit 0——只验正方向的话，一个恒真的
配置也能拿满分。错误原文与 2026-08-25 那次逐字一致。

**结论不变：复议条件不触发。** 本轮的改动是资产层**落在哪里**和**什么时候迁**，
不是它由什么构成，所以三件要跨栈的东西一件都没动——这次重跑确认了这个推断，而不是替代它。

⚠ **这两个探针仍然不在 `run.sh` 里，那是刻意的。** 它们要 `npm i`，而网关 0 的定义是
**$0 且自包含**；把一道会因为网络失败而红的门放进去，教出来的只是「这个红可以忽略」。
代价是它们只在有人想起来时才跑——所以每次改动资产层的构成或落点，重跑一次并在这里补一行。

## 2026-08-25 量到的

| | 检查器 | 合法用法 | 白名单外的区域名 |
|---|---|---|---|
| Vue 3 SFC | `vue-tsc` 3 | exit 0 | `error TS2322: Type '"sidebar"' is not assignable to type 'RegionId'` |
| React Native | `tsc` 5 | exit 0 | `error TS2322: Type '"sidebar"' is not assignable to type '"app-shell" \| …'` |

`REGION_META` 少一个键时两边都是 `error TS2741: Property 'stage' is missing`。

**结论：复议条件不触发。** 三件机制里前两件（`RegionId`、`REGION_META`）是纯 TypeScript，
与视图层无关；第三件（容器）在两个栈里都能自然表达，没有硬凑。

## 两个栈各自逼出来的东西

**Vue 把资产层拆成了两个文件。** SFC 导出类型不干净，所以 `regions.ts` 拿类型与元数据、
`Region.vue` 拿容器。这是两个端口里唯一的结构性改动，`audit.sh` 因此多了一个
`REGION_COMPONENT`——在 React 起点里它和 `REGION_TYPE` 是同一个文件，在 Vue 里不是。

**React Native 暴露了体检的三层 DOM 假设**，全部是实测的，不是推的：

1. 标记名写死了 `data-region`——RN 没有 DOM，容器盖的是 `testID`
2. 模式是 `<[a-z]`，编码的是「裸元素是小写的」——RN 里没有小写元素，一个都匹配不到
3. 即使前两条修好，`testID` 也**不是我们的命名空间**：它本来就是 e2e 钩子，
   grep 分不开「绕过」和「测试钩子」

前两条修了（`MARKER` 与大小写不敏感的标签），第三条修不了，改成明说判不了
（`MARKER_EXCLUSIVE="no"` → 检查 2b 报 skip）。修之前，一个写着
`<View testID="sidebar" />`（白名单外、不走容器）的 RN 项目，检查 1、2、2b **同时报绿**。

## 没有覆盖的

| 栈 | 状态 |
|---|---|
| Svelte | **没做**。与 Vue 同类（编译期检查 + 有 TS），预期同样通过，但那是预期不是测量 |
| 原生 JS | **没做**。它是声明过的降级路径：没有类型系统，编译期层整个失效，`ui-contract-assets` 要求明说而不是假装装上了 |
| Flutter / 原生 | 没做，且 `RegionId` 在非 TS 语言里是另一套形态 |

跨技术栈**同名**（借 shadcn token 命名的唯一理由）这一条**仍然没有判据在验**——
这两个探针验的是区域名机制，不是 token 名。记在 issue #6 第 7 笔。
