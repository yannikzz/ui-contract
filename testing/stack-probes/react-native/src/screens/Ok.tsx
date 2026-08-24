import { Text } from 'react-native'
import { Region } from '../ui/Region'

export function Ok() {
  return (
    <Region id="app-shell">
      <Region id="body">
        <Region id="nav"><Text>导航</Text></Region>
        <Region id="stage">
          <Region id="main">
            <Region id="main.content"><Text>内容</Text></Region>
            <Region id="main.actions"><Text>动作</Text></Region>
          </Region>
        </Region>
      </Region>
    </Region>
  )
}
