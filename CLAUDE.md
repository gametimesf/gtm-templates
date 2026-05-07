# CLAUDE.md

## Source of Truth

`src/` is the source of truth. `dist/` is generated output — never edit files in `dist/` directly.

## Build

```
npm run build    # generate dist/ from src/
npm run dev      # watch src/ and rebuild on change
```

Run `npm run build` after any change to `src/` before committing.

## Directory Structure

```
src/
  _shared.js               # injected into every template's sandboxed.js — shared helpers only
  <template-name>/
    info.json              # ___INFO___ section
    parameters.json        # ___TEMPLATE_PARAMETERS___ section
    sandboxed.js           # ___SANDBOXED_JS_FOR_WEB_TEMPLATE___ section (_shared.js prepended at build)
    permissions.json       # ___WEB_PERMISSIONS___ section
    notes.md               # ___NOTES___ section
    __tests__/
      <test-name>.js       # one JS file per scenario — @name JSDoc drives the GTM test name
dist/                      # built output — import these into GTM (do not edit directly)
samples/                   # reference Custom HTML tags (do not modify)
scripts/
  build.js                 # one-shot build
  watch.js                 # file watcher
  gtm-tpl-plugin.js        # build logic: assembles section files into .tpl format
```

## Adding or Modifying a Template

1. Edit the relevant file in `src/<template-name>/` — each section is its own file
2. Edit `src/_shared.js` for changes that apply to every template
3. Run `npm run build`
4. Import the updated `dist/<name>.tpl` into GTM and approve any new permissions

## Adding a New Template

1. Copy `src/_boilerplate/` to `src/<your-template-name>/`
2. Update each file — replace all `myGlobal`, `myParam`, and placeholder text with real values
3. Run `npm run build` — the plugin picks up any new subdirectory automatically

Directories prefixed with `_` (including `_boilerplate`) are ignored by the build.

## Adding or Modifying Tests

Each test is a plain JS file in `src/<template-name>/__tests__/`. The `@name` JSDoc tag drives the test name in GTM — the JSDoc block is stripped from the code before embedding.

```javascript
/**
 * @name Fires track with merged properties via bridge function
 */
var trackedName, trackedProps;
mock('copyFromWindow', function(key) { ... });
runCode({ eventName: 'search', ... });
assertApi('gtmOnSuccess').wasCalled();
```

- `@name` is required — the build will throw if it is missing
- Filename is for humans only (kebab-case, descriptive) — order does not matter
- File content below the JSDoc block is the raw test body: `mock(...)`, `runCode(...)`, `assertApi(...)`

## Adding a New Vendor to the Generic Tag

GTM does not support wildcard permissions. Each vendor global requires an explicit entry in `permissions.json`.

1. Edit `src/generic-js-tag/permissions.json` — add a `listItem` entry for the global
2. If the vendor uses dot notation (e.g. `ttq.track`), add two entries: one for the root object (read only) and one for the method (execute only)
3. Run `npm run build`
4. Re-import `dist/generic-js-tag.tpl` into GTM and approve the new permission

## Error Reporting

All templates call `reportError(message, ctx)` (injected from `_shared.js`) before `gtmOnFailure()`.

- Error messages follow the pattern: `[GTM:error] <specific description>`
- The `ctx` object always includes `template` and the relevant event identifier (e.g. `eventName`, `pageType`)
- `reportError` forwards to `window._reportError`, which is set by the **Error Bridge Custom HTML tag** in GTM
- The Error Bridge routes errors to both Sentry (`captureMessage`) and Datadog RUM (`addError`)
- If the Error Bridge tag has not fired, `reportError` calls are silently dropped — not an exception

The Error Bridge tag must fire before all other tags (All Pages, high firing priority).

## Sandboxed JS Rules

- No `try/catch` — unsupported by the GTM sandbox parser. Use guard checks instead.
- No `Promise` / `async/await` — no async execution model in the sandbox.
- No DOM access — `document`, `querySelector`, `appendChild` are unavailable.
- No `Object.assign` — use an inline `for...in` merge loop.
- No ES6+ syntax — avoid spread, destructuring, arrow functions, template literals.
- All `require()` calls must use GTM's own sandboxed APIs (`callInWindow`, `copyFromWindow`, `logToConsole`).
- Every window global that is read or called must be declared in `___WEB_PERMISSIONS___`.

## GTM Permissions Format

```json
{
  "type": 3,
  "mapKey": [
    {"type": 1, "string": "key"},
    {"type": 1, "string": "read"},
    {"type": 1, "string": "write"},
    {"type": 1, "string": "execute"}
  ],
  "mapValue": [
    {"type": 1, "string": "<globalName>"},
    {"type": 8, "boolean": true},   // read
    {"type": 8, "boolean": false},  // write
    {"type": 8, "boolean": true}    // execute
  ]
}
```

Set only the permissions actually needed — don't grant read + execute if only execute is required.
