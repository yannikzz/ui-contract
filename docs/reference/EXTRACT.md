# 在本地提取 `plugin-eval.md`

`plugin eval` 是 early access，**没有公开文档页**——官方参考文档只内嵌在 `claude` CLI 二进制里。

这份文档是 Anthropic 的文字，不随本仓库的 MIT 协议分发，所以**不提交**：它在 `.gitignore`
里，每台机器自己生成（见 ADR-0016）。clone 之后、以及升级 CLI 之后，在仓库根目录跑下面这段。

```sh
CLI=$(ls -d ~/.local/share/claude/versions/* | sort -V | tail -1)
python3 -I - "$CLI" <<'PY'
import re, sys
from compression import zstd           # Python 3.14+ 标准库
cli = sys.argv[1]
b = open(cli, 'rb').read()
# 文档以 zstd 帧内嵌（Bun 的 /$bunfs/root/plugin-eval-<hash>.md.zst）。帧在二进制里
# 没有可靠的长度索引，所以逐个魔数试解压，认标题。
MAGIC, hits = b'\x28\xb5\x2f\xfd', []
i = b.find(MAGIC)
while i != -1:
    try:
        d = zstd.ZstdDecompressor().decompress(b[i:i + 4_000_000])
        if d.lstrip().startswith(b'# Plugin eval ('): hits.append(d)
    except zstd.ZstdError:
        pass
    i = b.find(MAGIC, i + 1)
if len(hits) != 1:
    sys.exit(f'找到 {len(hits)} 份以「# Plugin eval (」开头的文档，期望恰好 1 份——CLI 的打包方式又变了')
ver = re.search(r'versions/([^/]+)$', cli)
head = f'<!-- 从 claude CLI {ver.group(1) if ver else cli} 逐字提取，见 EXTRACT.md。Anthropic 的文字，不提交（ADR-0016）。 -->\n\n'
open('docs/reference/plugin-eval.md', 'w', encoding='utf-8').write(head + hits[0].decode('utf-8'))
print(f'docs/reference/plugin-eval.md ← {cli}（{len(hits[0])} 字节）')
PY
```

对照 `claude plugin eval --help` 抽查一遍：文档里的选项表自称与 `--help` 同步
（"A test keeps this table in sync with the registered flags"），两边对不上就说明提取歪了。

**打包方式变过一次。** 2.1.238 时文档是 JS 字符串字面量，`strings` 加反转义就能取出；
最晚到 2.1.288 已改成 zstd 压缩的内嵌文件，明文搜不到。脚本找不到恰好一份时会直接失败，
而不是写出一个空文件或半截文件。
