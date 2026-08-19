#!/bin/sh
set -eu
mkdir -p src/layouts src/components src/pages

cat > package.json <<'EOF'
{
  "name": "ops-console",
  "private": true,
  "dependencies": { "react": "^19.0.0", "react-dom": "^19.0.0" },
  "devDependencies": { "tailwindcss": "^4.1.0", "typescript": "^5.8.0" }
}
EOF

cat > tailwind.config.js <<'EOF'
/** 运营后台的既有 token。这是这个项目里值的来源。 */
export default {
  theme: {
    extend: {
      colors: {
        brand:   { DEFAULT: '#2563eb', hover: '#1d4ed8' },
        surface: { base: '#ffffff', sunken: '#f8fafc', border: '#e2e8f0' },
        state:   { ok: '#16a34a', warn: '#d97706', bad: '#dc2626' },
      },
      fontSize: { xs: '12px', sm: '13px', base: '14px', lg: '16px', xl: '20px' },
      borderRadius: { sm: '4px', md: '6px', lg: '10px' },
    },
  },
}
EOF

# 已有视觉规范——里面**混着结构内容**，这正是要被搬走的部分
cat > design.md <<'EOF'
# 运营后台视觉规范

## 1. 色彩
主色 `#2563eb`，hover 态 `#1d4ed8`。卡片面 `#ffffff`，页面底 `#f8fafc`，描边 `#e2e8f0`。
状态色：成功 `#16a34a`、警告 `#d97706`、错误 `#dc2626`。状态色只用于小标签和状态点。

## 2. 字号
12 / 13 / 14 / 16 / 20，四级文字层级，不再加第五级。

## 3. 圆角与阴影
小元件 4px，卡片 6px，弹层 10px。阴影只有一档。

## 4. 布局骨架
左侧导航固定 220px 宽，收起后 56px。主区最小可用宽 640px，低于这个宽度导航先收。
右侧属性面板 360px，固定不可拖拽。
列表页结构：顶部一条筛选条，下面是表格，点行在右侧开属性面板。

## 5. 按钮
主按钮实心主色，次按钮描边，幽灵按钮无边框。三级，不再加。

## 6. 表格
行高 40px，斑马纹关闭，hover 行底色 `#f8fafc`。
EOF

cat > src/layouts/AppLayout.tsx <<'EOF'
import { Sidebar } from '../components/Sidebar'

/** 全局外壳。所有页面都套在这里。 */
export function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-surface-sunken">
      <Sidebar />
      <main className="flex-1 overflow-auto">{children}</main>
    </div>
  )
}
EOF

cat > src/components/Sidebar.tsx <<'EOF'
export function Sidebar() {
  return (
    <nav className="w-[220px] shrink-0 border-r border-surface-border bg-white">
      <div className="px-4 py-3 text-lg font-medium">运营后台</div>
      <a href="/users">用户</a>
      <a href="/orders">订单</a>
      <a href="/settings">设置</a>
    </nav>
  )
}
EOF

# 同一个筛选条被四个页面各自 import，props 各不相同——真实的熵
cat > src/components/FilterBar.tsx <<'EOF'
/** 筛选条。四个页面各用各的 props，没人统一过。 */
export function FilterBar(props: Record<string, unknown>) {
  return <div className="flex gap-2 border-b border-surface-border p-3">{JSON.stringify(props)}</div>
}
EOF

for p in UserListPage OrderListPage OrderDetailPanel SettingsPage AuditLogPage; do
  cat > "src/pages/$p.tsx" <<EOF
import { FilterBar } from '../components/FilterBar'

export function $p() {
  return (
    <div className="p-4">
      <FilterBar scope="$p" />
      <div className="rounded-md border border-surface-border bg-white">$p 的内容</div>
    </div>
  )
}
EOF
done

cat > tsconfig.json <<'EOF'
{ "compilerOptions": { "strict": true, "jsx": "react-jsx", "target": "ES2022", "moduleResolution": "bundler", "module": "ESNext", "noEmit": true } }
EOF
