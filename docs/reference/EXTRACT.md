# 重新提取 `plugin-eval.md`

`plugin eval` 是 early access，**没有公开文档页**——官方参考文档只以字符串形式内嵌在
`claude` CLI 二进制里。升级 CLI 之后重跑下面这段，把 `plugin-eval.md` 换掉。

```sh
CLI=$(ls -d ~/.local/share/claude/versions/* | sort -V | tail -1)
strings "$CLI" | grep -n 'Plugin eval (`claude plugin eval`)' | head
```

拿到行号 N 之后：

```sh
strings "$CLI" | sed -n "${N}p" > /tmp/blob.txt
python3 - <<'PY'
import re
s = open('/tmp/blob.txt', encoding='utf-8', errors='replace').read()
st = s.find('="# Plugin eval (`claude plugin eval`)') + 2
i, out = st, []
while i < len(s):                      # 逐字符走完这个 JS 字符串字面量
    if s[i] == '\\': out.append(s[i:i+2]); i += 2; continue
    if s[i] == '"': break
    out.append(s[i]); i += 1
d = ''.join(out)
for a, b in (('\\n','\n'), ('\\"','"'), ("\\'","'"), ('\\`','`'), ('\\\\','\\')):
    d = d.replace(a, b)
d = re.sub(r'\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1), 16)), d)
open('/tmp/plugin-eval.md', 'w', encoding='utf-8').write(d)
PY
```

对照 `claude plugin eval --help` 抽查一遍再提交：文档里的选项表自称与 `--help` 同步
（"A test keeps this table in sync with the registered flags"），两边对不上就说明提取歪了。
