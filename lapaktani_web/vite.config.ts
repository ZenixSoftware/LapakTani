import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    allowedHosts: [
      'ppl-lapaktani.velosixraptor.my.id',
      '.velosixraptor.my.id',
      'localhost',
    ],
  },
  preview: {
    host: true,
    allowedHosts: [
      'ppl-lapaktani.velosixraptor.my.id',
      '.velosixraptor.my.id',
      'localhost',
    ],
  },
})
