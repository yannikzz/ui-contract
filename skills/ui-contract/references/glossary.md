# Glossary — canonical term renderings

The skill body is in English; deliverables follow the user's language. That combination has one failure mode: **the same concept gets translated differently on every run**, so two projects (or two agents on one project) end up unable to talk to each other.

This table pins the rendering. When producing deliverables in a language listed here, use these exact terms. When producing deliverables in a language *not* listed here, pick one rendering per concept, **write your choices into a glossary section of the structural spec**, and stay consistent.

| English | 中文 | Notes |
|---|---|---|
| UI contract | UI 契约 | The two specs + wireframe taken together |
| structural spec (`layout.md`) | 结构规范 | Never 布局文档 — it is a contract, not a description |
| visual spec (`design.md`) | 视觉规范 | |
| the swappability line | 切线 | The one cut: does it change when the brand skin changes? |
| placement decision tree | 落位决策树 | Never 归属判定树 / 放置流程 |
| to place something (a new need) | 落位 | Verb. 「走一遍决策树落位」 |
| region | 区域 | A structural container with a name |
| region-name allowlist | 区域名白名单 | |
| must hold / must not hold (table columns) | 允许放 / **禁止放** | The 禁止放 column is what makes it a spec |
| page archetype | 页型 | Never 页面类型 — too easily confused with a route |
| focus slot | 聚焦槽 | The single slot that shows one object's facet at a time |
| first-class object | 一等对象 | Has identity, can be opened alone, has a lifecycle |
| facet (of an object) | 切面 | What a focus-slot panel shows |
| content routing | 内容分流 | Which class of content lands where |
| nav admission rules | 导航准入 | |
| action / queue / library (nav segments) | 动作 / 队列 / 全局库 | Only if the project's own test produces these three |
| degradation (on narrowing) | 降级 | Never 响应式 — this is a structural cascade, not breakpoints |
| signal rail | 信号条 | What a collapsed column must leave behind |
| overlay | 覆盖层 | The orthogonal full-screen layer |
| low-fidelity wireframe | 低保真线框 | Never 原型图 alone — fidelity is the point |
| annotation layer | 区域标注层 | The inspect mode over the wireframe |
| deliberate tradeoffs | 刻意的取舍 | The list that stops the next agent from "fixing" them |
| anti-pattern | 反模式 | |
| overturned decisions | 被推翻的 | Appendix that must never be deleted from |
| non-happy-path states | 非常态 | empty / loading / partial failure / whole-region failure |
| cost (of an option) | 代价 | Every interview option needs one |
| enforcement | 强制机制 | The three layers |
