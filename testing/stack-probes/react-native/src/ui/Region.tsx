// 资产层第 3 件的 React Native 形态。
//
// 关键差别：**没有 DOM，就没有 data-* 属性**。运行时标记改写进 testID，
// 按 region.tsx.template 的原话——「用**完全相同的字符串**，不要另起一个更好读的名字」。
import { View, type ViewProps } from 'react-native'
import type { ReactNode } from 'react'
import type { RegionId } from './regions'

export function Region({
  id,
  children,
  ...rest
}: { id: RegionId; children?: ReactNode } & Omit<ViewProps, 'testID' | 'children'>) {
  return (
    <View testID={id} accessibilityLabel={id} {...rest}>
      {children}
    </View>
  )
}
