/**
 * 展示层夹具。**调用点的换行形态是这份夹具的全部意义**——
 * 只有单行调用点的话，四条曾经永远返回绿的检查会继续返回绿。
 */
import { Region } from './ui/region'

export function App() {
  return (
    <Region
      id="app-shell"
      className="flex min-h-0 w-full"
    >
      <Region id="nav" className="w-56 shrink-0" />
      <Region
        id="main"
        className="min-w-0 flex-1"
      >
        <Region
          id="main.pagehead"
          className="flex items-center justify-between px-5 py-3"
        />
      </Region>
      <Region id="inspector" className="w-90 shrink-0" />
    </Region>
  )
}
