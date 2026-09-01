---
type: regex
target: files
pattern: "^\\.ui-contract-local/assets/"
flags: "m"
match: contains
weight: 1
---

结构半场里**该做**的事之一：资产层建起来，落在工作台。

这一条和 `no-production-code-in-structural-half` 是一对，缺一不可。只有禁令，agent 什么都不做也能拿
满分；只有达成，它可以既建在工作台**又**建一份进生产树。两条一起，位置才被真正判定。

## 这笔观测账是这次改动到期的

`testing/evals/README.md` 长期记着一笔接受的代价：`ui-contract-assets` / `ui-contract-wireframe`
/ `ui-contract-enforce` 三个包的产物没有一条判据看过。当时接受它的理由是那些产物属于**跑过头**，
不观测只是省钱。半场的划分把它们变成了**该做的**，理由随之失效。

## 锚：`config.md` 的 `asset-staged` 默认路径

**什么能过**：用户把 `asset-staged` 配到别处。这条锚在默认值上，不是锚在规则上——规则是「在
工作台里」，而工作台路径可配。判据读不到 `config.md`，所以只能锚默认值。用户改路径时这条会
误判为红；那是**响的**失败，比绿着漏判好。
