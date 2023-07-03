import { defineConfig } from 'astro/config';
import tailwind from "@astrojs/tailwind";
import alpinejs from "@astrojs/alpinejs";

// https://astro.build/config
export default defineConfig({
  srcDir: './web/src',
  publicDir: './public',
  outDir: './web-out',
  build: {
    format: 'file',
  },
  integrations: [tailwind(), alpinejs()]
});
