import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// The project root is this directory. The asset layer (src/ui/region.tsx) is
// production code and lives here; the wireframe is rehearsal and lives in the
// workbench, `.ui-contract-local/`, which a real project does not commit.
//
// This example DOES commit it — a declared deviation, because the example
// exists to be read. See examples/README.md.
//
// `root` below is the wireframe, two levels under this directory, and `fs.allow`
// entries resolve against `root` — not against this file. So `../..` IS this
// directory: the shallowest entry that still covers everything the wireframe
// imports from outside its own root — `../../../src/ui/region` (the asset layer),
// `../../../src/tokens.css` and `../../tokens.input.json`. `..` reaches only
// `.ui-contract-local/`, so under it the two `src/` imports 403 under `vite dev`
// while `tokens.input.json` still resolves — measured, both ways.
//
// `vite build` never consults `fs.allow`, so a green build is not evidence this
// value is right. Only `vite dev` is.
export default defineConfig({
  root: '.ui-contract-local/wireframe',
  plugins: [react(), tailwindcss()],
  server: { fs: { allow: ['../..'] } },
})
