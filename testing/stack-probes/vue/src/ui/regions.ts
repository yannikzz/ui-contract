// 资产层第 1、2 件：白名单的类型形态 + 区域元数据。纯 TS，与技术栈无关。
export type RegionId =
  | 'app-shell'
  | 'title-row'
  | 'body'
  | 'nav'
  | 'stage'
  | 'main'
  | 'main.content'
  | 'main.actions'

export const REGION_META: Record<RegionId, { label: string; desc: string }> = {
  'app-shell': { label: 'App shell', desc: '只放结构；自己不渲染业务内容' },
  'title-row': { label: 'Window controls', desc: '放窗口控件；禁止业务信息与常驻信号' },
  body: { label: 'Body', desc: '放导航与舞台；不放业务内容' },
  nav: { label: 'Navigation', desc: '各原型下内容一致；禁止当前上下文内容' },
  stage: { label: 'Stage', desc: '放当前原型的主体；不放全局控件' },
  main: { label: 'Main card', desc: '放主卡片；不放导航' },
  'main.content': { label: 'Main content', desc: '放主体内容；不放动作按钮' },
  'main.actions': { label: 'Action area', desc: '放动作；不放内容' },
}
