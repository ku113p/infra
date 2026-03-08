import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import webfontDownload from "vite-plugin-webfont-dl";

export default defineConfig({
  plugins: [
    react(),
    webfontDownload([
      "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap",
    ]),
  ],
  resolve: {
    alias: {
      react: "preact/compat",
      "react-dom": "preact/compat",
      "react/jsx-runtime": "preact/jsx-runtime",
    },
  },
});
