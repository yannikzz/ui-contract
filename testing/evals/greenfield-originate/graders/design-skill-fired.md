---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?ui-contract-design"'
min: 1
weight: 1
---

这个用例的全部理由是 `originate` 分支跑在 design 步。`design-md-written` 只看文件
落没落地，而文件是谁写的它不问——两条一起才说明「规范由这个包生成」。

VERIFIED 2026-08-21，**只有正方向**：三次 with run 全部命中。
负方向拿不到——with-only 判据是被**丢出**对照臂的，不是在那里判红的（量过，见 README）。
