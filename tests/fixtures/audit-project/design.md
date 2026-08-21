# design.md（夹具）

视觉规范只写规则，值住 token 文件。

- 正文字号取自 token 的 `--text-body`，不在这里写死。
- 半年后你会同时有 13px / 13.5px / 15px——这句里的数字是反例，不是定义。
- 正文与背景的对比度至少 4.5:1。这个阈值只在这里出现一次，器具与体检都从这里读。

## 命名声明

命名遵循：**shadcn core（19 个）**

三个来源关键词是固定的 ASCII（`borrowed` / `this project` / `not used`），
因为脚本按关键词认这张表——产物写成哪种语言都能认出来。

| Token | 来源 |
|---|---|
| `card` | borrowed |
| `card-foreground` | borrowed |
| `brand` | this project |
| `surface` | this project |
| `secondary` | not used — 夹具只有一级动作 |
