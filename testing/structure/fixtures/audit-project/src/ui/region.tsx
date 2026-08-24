/** 资产层夹具：白名单的类型形态 + 元信息 + 结构容器。 */
import type { ReactNode } from 'react'

export type RegionId =
  | 'app-shell'
  | 'nav'
  | 'main'
  | 'main.pagehead'
  | 'inspector'

export const REGION_META: Record<RegionId, { label: string; desc: string }> = {
  'app-shell': { label: 'App shell', desc: '只并排导航与工作区。禁止直接承载内容。' },
  nav: { label: 'Navigation', desc: '只放三个子区。禁止放当前页面的内容。' },
  main: { label: 'Main', desc: '当前页型的主体。禁止放全局导航项。' },
  'main.pagehead': { label: 'Page head', desc: '页标题 + 页级动作。禁止放批量动作。' },
  inspector: { label: 'Inspector', desc: '单对象属性。禁止放列表。' },
}

export function Region({
  id,
  children,
  className = '',
}: {
  id: RegionId
  children?: ReactNode
  className?: string
}) {
  return (
    <div data-region={id} className={className}>
      {children}
    </div>
  )
}
