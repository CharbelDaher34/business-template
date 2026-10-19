import path from "node:path"
import tailwindcss from "@tailwindcss/vite"
import { tanstackRouter } from "@tanstack/router-plugin/vite"
import react from "@vitejs/plugin-react-swc"
import { defineConfig } from "vite"

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    // Listen inside the container; compose.yml publishes it as APP_PORT.
    host: "0.0.0.0",
    port: 5173,
    strictPort: true,
    // The browser reaches the dev server on APP_PORT (via SSH port forwarding),
    // so hot reload must connect back on that port too.
    hmr: { clientPort: Number(process.env.APP_PORT) || undefined },
    // The API and its docs (/api/docs) are served by the backend container.
    proxy: {
      "/api": { target: "http://backend:8000" },
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
  resolve: {
    alias: {
      "@": path.resolve(import.meta.dirname, "./src"),
    },
  },
  plugins: [
    tanstackRouter({
      target: "react",
      autoCodeSplitting: true,
    }),
    react(),
    tailwindcss(),
  ],
})
