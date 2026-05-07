import { watch } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { buildAll } from './gtm-tpl-plugin.js';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

buildAll();

watch(path.join(ROOT, 'src'), { recursive: true }, (event, filename) => {
  console.log('[gtm-tpl] ' + event + ': ' + filename + ' — rebuilding...');
  buildAll();
});

console.log('[gtm-tpl] Watching src/ for changes...');
