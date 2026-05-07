import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT      = path.resolve(__dirname, '..');
const SRC_DIR   = path.join(ROOT, 'src');
const DIST_DIR  = path.join(ROOT, 'dist');

function parseTest(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');

  const nameMatch = raw.match(/\/\*\*[\s\S]*?@name\s+(.+?)\n[\s\S]*?\*\//);
  if (!nameMatch) throw new Error('[gtm-tpl] Missing @name in ' + filePath);
  const name = nameMatch[1].trim();

  // Strip the leading JSDoc block so only executable code reaches GTM
  const code = raw.replace(/\/\*\*[\s\S]*?\*\/\s*/, '').trim();
  const indented = code.split('\n').map(line => '    ' + line).join('\n');

  return '- name: ' + name + '\n  code: |-\n' + indented;
}

function buildTests(dir) {
  const testsDir = path.join(dir, '__tests__');
  if (!fs.existsSync(testsDir)) return '';

  const scenarios = fs.readdirSync(testsDir)
    .filter(f => f.endsWith('.js'))
    .sort()
    .map(file => parseTest(path.join(testsDir, file)));

  return 'scenarios:\n' + scenarios.join('\n');
}

function buildAll() {
  const shared = fs.readFileSync(path.join(SRC_DIR, '_shared.js'), 'utf8').trim();

  const templates = fs.readdirSync(SRC_DIR, { withFileTypes: true })
    .filter(d => d.isDirectory() && !d.name.startsWith('_'))
    .map(d => d.name);

  for (const name of templates) {
    const dir  = path.join(SRC_DIR, name);
    const read = (file) => fs.readFileSync(path.join(dir, file), 'utf8').trim();

    const tpl = [
      '___INFO___\n\n'                          + read('info.json'),
      '___TEMPLATE_PARAMETERS___\n\n'           + read('parameters.json'),
      '___SANDBOXED_JS_FOR_WEB_TEMPLATE___\n\n' + shared + '\n\n' + read('sandboxed.js'),
      '___WEB_PERMISSIONS___\n\n'               + read('permissions.json'),
      '___NOTES___\n\n'                         + read('notes.md'),
      '___TESTS___\n\n'                         + buildTests(dir),
    ].join('\n\n') + '\n';

    fs.writeFileSync(path.join(DIST_DIR, name + '.tpl'), tpl);
    console.log('[gtm-tpl] Built dist/' + name + '.tpl');
  }
}

export { buildAll };
