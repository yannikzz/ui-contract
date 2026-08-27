/**
 * 契约自断言。**没有任何文件 import 它，但它跟着全项目一起过类型检查。**
 *
 * 下面每一行都是 layout.md 明令禁止的写法。承载规则的是 `@ts-expect-error`：
 * 禁令还成立时这一行报错、指令把错误消费掉；**谁把禁止的成员加回去，错误就消失了，
 * 指令随之变成「未使用」，tsc 在这个文件上报 TS2578。**
 *
 * 也就是说：一条被悄悄删掉的禁令会**弄红构建**，而不是安静地不见。
 *
 * 为什么需要它——省略只在一个方向上被强制：
 * 编译器抓的是「代码用了禁止的成员」，没有任何东西抓「有人把成员加回来」。
 * 加回来的那一刻，所有既有调用点照样编译通过，联合类型上方那句「刻意省略」的注释
 * 开始描述一条它已经没有的规则，而**输出一模一样**。
 *
 * 两个机械细节，错了都会静悄悄地失效：
 *   · 必须 `export`。`noUnusedLocals` 下一个没人用的局部变量本身就是错误，
 *     那时文件会因为一个跟契约无关的理由变红。
 *   · 必须落在 tsconfig 的 include 里。它没被任何人 import——正是窄 include 会漏掉的那种文件，
 *     而一个没有编译器读过的 .assert.ts，在输出里和一个通过了的完全一样。
 */
import type { PageWithInspector, TableColumnKind, InspectorKind, StatusKind } from './ui/region'

// layout.md §6.2 / §10-1 —— 单行操作的唯一宿主是 inspector.foot，没有操作列
// @ts-expect-error 'actions' 刻意不在 TableColumnKind 里
export const _noActionColumn: TableColumnKind = 'actions'

// layout.md §4.3 —— 向导页没有属性面板，这是硬禁止，不是「暂时没做」
// @ts-expect-error 'wizard' 刻意不在 PageWithInspector 里
export const _noWizardInspector: PageWithInspector = 'wizard'

// layout.md §4.2 矩阵 —— P3 表单页同样没有属性面板
// @ts-expect-error 'form' 刻意不在 PageWithInspector 里
export const _noFormInspector: PageWithInspector = 'form'

// layout.md §5.1 / §5.4 —— 属性面板只有 1 型；加第 2 型要先过三条判据并写进文档
// @ts-expect-error 面板类型枚举刻意只有 'content-item'
export const _noSecondInspectorKind: InspectorKind = 'user-account'

// layout.md §2 —— 区域名白名单之外的名字写不出来
// 这一条与上面四条不同：它守的是 RegionId 这个**正向**白名单，
// 而不是某个成员的缺席。放在一起是因为破坏方式相同——往联合里加一个成员。
import type { RegionId } from './ui/region'
// @ts-expect-error 白名单外的区域名不可写
export const _noAdHocRegion: RegionId = 'sidebar'

// layout.md §6.4 —— 语义类是封闭集，五类。加第六类要走 §9 变更流程
// @ts-expect-error 'archived' 不是一个语义类：已归档归 neutral，刻意不给它自己的类
export const _noSixthStatusKind: StatusKind = 'archived'
