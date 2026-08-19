import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// The project root is this directory, not wireframe/. The asset layer
// (src/ui/region.tsx) is production code and lives here; the wireframe is one
// throwaway directory inside the project that imports from it. Same layout a
// real project would have — which is why the templates' import path is
// `../../src/ui/region`.
export default defineConfig({
  root: 'wireframe',
  plugins: [react(), tailwindcss()],
  server: { fs: { allow: ['..'] } },
})
