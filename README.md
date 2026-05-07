# GTM Hightouch Custom Templates

GTM Custom Template replacements for Hightouch analytics event tracking tags. Eliminates DOM bloat caused by Custom HTML tags in Single Page Applications.

---

## The Problem

Google Tag Manager's **Custom HTML** tag type works by injecting a `<script>` element into the DOM each time the tag fires. In a traditional multi-page site this is a non-issue — the DOM is destroyed on every navigation. In a **Single Page Application (SPA)**, the DOM persists across route changes, so every tag fire appends another `<script>` node. Over a browsing session, hundreds of orphaned script elements accumulate, degrading performance and making the DOM harder to debug.

---

## The Solution

GTM **Custom Templates** use Sandboxed JavaScript — a restricted execution environment that runs tag logic directly without creating any DOM nodes. The result is functionally identical analytics tracking with zero DOM pollution, regardless of how many times a tag fires.

---

## Scope: What Is (and Isn't) Converted

**Event tracking tags are converted to Custom Templates** — these are the source of the DOM bloat because they fire on every SPA route change.

**The init tag (`hightouch-init.html`) remains a Custom HTML tag.** The Hightouch SDK stub setup requires setting callable functions directly on `window.htevents`, which depends on direct page context. GTM's Sandboxed JS isolation boundary makes this unreliable. Critically, the init tag also fires **once per page load** — not on every route change — so its DOM impact is a single unavoidable `<script>` element needed to load any external SDK.

---

## What's in This Repo

```
src/
  _shared.js          Injected into every template's sandboxed JS at build time
  <template-name>/
    info.json         Template metadata
    parameters.json   GTM parameter definitions
    sandboxed.js      Sandboxed JS logic
    permissions.json  Window global permissions
    notes.md          GTM notes section
    __tests__/
      <test-name>.js  One file per test — @name JSDoc drives the GTM test name
dist/               Built .tpl files — import these into GTM (do not edit directly)
samples/            Original Custom HTML tags and reference files
scripts/            Build tooling
DEPLOYMENT.md       Automated deployment options (GitHub Actions + GTM API)
```

### Build Workflow

Source lives in `src/` — `dist/` is generated output.

```
npm run build     # builds all dist/*.tpl from src/
npm run dev       # watches src/ and rebuilds on change
```

**Never edit `dist/` directly.** Changes must go through `src/` and be rebuilt.

### Writing Tests

Each test is a plain `.js` file in `src/<template-name>/__tests__/`. A JSDoc `@name` tag at the top drives the test name in GTM — the block is stripped from the code before embedding.

```javascript
/**
 * @name Fires track with merged properties via bridge function
 */
var trackedName, trackedProps;
mock('copyFromWindow', function(key) {
  if (key === '_htTrack') { return function() {}; }
});
runCode({ eventName: 'search', baseProperties: { user_id: 'u1' } });
assertApi('gtmOnSuccess').wasCalled();
```

- `@name` is required — the build throws if it is missing
- Filename is for humans only (kebab-case, descriptive) — execution order does not matter
- File content below the JSDoc block is raw GTM test body: `mock(...)`, `runCode(...)`, `assertApi(...)`

### Templates

| File | Replaces | Hightouch SDK Call |
|---|---|---|
| `hightouch-track.tpl` | `hightouch-catchall.html`, `hightouch-click.html` | `htevents.track(eventName, props)` |
| `hightouch-pageview.tpl` | `hightouch-pageview.html` | `htevents.page(pageType, title, props)` |
| `hightouch-identify.tpl` | `hightouch-identify.html` | `htevents.setAnonymousId()` + `htevents.identify(userId, traits)` |

---

## Advantages of Sandboxed JS over Custom HTML

### 1. No DOM Bloat
Custom HTML tags inject a `<script>` element every time they fire. Templates execute in GTM's sandboxed runtime — no DOM nodes are created or left behind. On a typical SPA session with dozens of route changes, this can mean the difference between hundreds of orphaned script elements and zero.

### 2. Proper Tag Sequencing via `gtmOnSuccess` / `gtmOnFailure`
Custom HTML tags have no native way to signal completion or failure to GTM. Templates call `data.gtmOnSuccess()` or `data.gtmOnFailure()`, which integrates correctly with GTM's tag sequencing (setup/cleanup tags) and built-in exception alerting. If `htevents` is missing the failure is surfaced to GTM's monitoring rather than silently swallowed.

### 3. Built-in Unit Testing
The GTM Template Editor includes a unit test runner. Each template ships with tests covering the happy path and missing `htevents`. These run inside GTM before any container publish — no external test framework or build step needed.

### 4. Controlled Permissions Model
Sandboxed JS templates declare exactly which browser APIs they need (e.g. `copyFromWindow`). GTM enforces these permissions at import time and surfaces them to reviewers in the template UI. Custom HTML tags have unrestricted access to the full browser API with no visibility into what they actually use.

### 5. Reusable, Parameterised Tags
Each template exposes typed parameters with help text and validation. A single `hightouch-track.tpl` covers both the catchall and click use cases — the difference is just parameter configuration per tag instance. Adding a new event type requires a new tag instance, not a new copy-pasted HTML file.

---

## Sandboxed JS API Reference

The following substitutions are used throughout the templates. Native browser globals are not available in Sandboxed JS — GTM provides purpose-built equivalents via `require()`.

| Standard JS | Sandboxed JS Equivalent |
|---|---|
| `window.htevents` | `require('copyFromWindow')('htevents')` |
| `window.fbq(...)` | `require('callInWindow')('fbq', ...)` |
| `Object.assign(...)` | inline `for...in` loop |
| `console.log(...)` | `require('logToConsole')(...)` |
| Tag completion signal | `data.gtmOnSuccess()` / `data.gtmOnFailure()` |

---

## Sandboxed JS Capabilities and Limitations

GTM's Sandboxed JavaScript is a restricted subset of JavaScript. Understanding what it can and cannot do determines whether a tag can be converted to a Custom Template or must remain as Custom HTML.

### What Sandboxed JS Can Do

| Capability | Notes |
|---|---|
| Call synchronous window functions | Via `callInWindow('fnName', args)` — the function must be declared in `___WEB_PERMISSIONS___` |
| Read window globals | Via `copyFromWindow('key')` |
| Pass flat objects as properties | Key-value pairs, strings, numbers, booleans |
| Pass pre-computed objects | Via a GTM Custom JS variable referenced as the `buildPayload` parameter — use this for nested structures |
| Standard control flow | `if/else`, `for`, `while`, `switch` |
| Basic data operations | String concatenation, arithmetic, array iteration |
| Log to console | Via `require('logToConsole')` |
| Signal tag completion | `data.gtmOnSuccess()` / `data.gtmOnFailure()` |

### What Sandboxed JS Cannot Do

These are hard limitations of the GTM sandbox — not workaroundable within a template.

| Limitation | Why it matters | Workaround |
|---|---|---|
| **Promises / async/await** | No async execution model exists in the sandbox | Keep tag as Custom HTML |
| **`crypto.subtle`** (SHA-256 etc.) | Async Promise-based API — unavailable | Keep tag as Custom HTML. The `ttq-identify` tag is the example: it hashes a phone number before sending, which requires async crypto |
| **`try/catch/finally`** | Explicitly unsupported by the GTM sandbox parser | Structure code defensively with guard checks before calling |
| **DOM manipulation** | `document.createElement`, `querySelector`, `appendChild` etc. are unavailable | Keep tag as Custom HTML if DOM access is required |
| **`setTimeout` / `setInterval`** | No timer APIs exist | No workaround — async retry logic cannot be implemented in templates |
| **`fetch` / `XMLHttpRequest`** | No direct HTTP request APIs | Use GTM's `sendPixel` for fire-and-forget GET requests |
| **`Object.assign`** | Not available via `require()` | Use an inline `for...in` merge loop |
| **Spread / destructuring syntax** | ES6+ syntax support is unreliable in the sandbox | Use explicit variable assignments instead |
| **`localStorage` / `sessionStorage`** | Direct storage access is blocked | Use GTM's storage APIs via `require('localStorage')` etc. |
| **Dynamic code execution** | Blocked entirely for security | No workaround |
| **Arbitrary `require()`** | Only GTM's own sandboxed APIs are available | Cannot import npm packages or external modules |
| **Wildcard global permissions** | `access_globals` keys must be valid JS identifiers — wildcards are rejected | Declare each vendor global explicitly in `___WEB_PERMISSIONS___` |
| **Nested objects in the Properties table** | The key-value table parameter only supports flat string values | Pass nested structures via a GTM Custom JS variable referenced as `buildPayload` |

### The Custom HTML Decision Rule

Convert a tag to a Custom Template **unless** it requires any of:

- Async operations (Promises, `crypto.subtle`, callbacks that resolve later)
- DOM manipulation during the call
- `try/catch` around the SDK call for error handling

Tags that fire **once per page load** (not on every SPA navigation) have lower conversion priority — their DOM impact is a single `<script>` element, not an accumulating one. The Hightouch init tag is the canonical example.

### Adding a New Vendor to the Generic Tag

The generic template cannot use wildcard permissions — each vendor's window global must be explicitly declared in `src/generic-js-tag/permissions.json`. To add a new vendor:

1. Add an entry to `src/generic-js-tag/permissions.json` with the global name, `read: true`, `write: false`, `execute: true`
2. If the vendor uses dot notation (e.g. `ttq.track`), add two entries: root object (read only) and the method (execute only)
3. Run `npm run build`
4. Re-import `dist/generic-js-tag.tpl` into GTM and approve the new permission

Current declared vendors: `fbq` (Meta), `spdt` (Spotify), `ttq.track` (TikTok), `DD_RUM` (Datadog), `ire` (Impact Radius), `podscribe` (Podscribe), `_uetqPush` (Microsoft Ads)

---

## Importing into GTM

1. Run `npm run build` to generate `dist/`
2. In GTM, go to **Templates → Tag Templates → New**
3. Click the menu (⋮) → **Import**
4. Select a `.tpl` file from the `dist/` directory
5. Review the permissions GTM surfaces, then click **Save**
6. Repeat for each template

Run the built-in **unit tests** (Templates editor → Run Tests) for each template before creating tag instances.

See [`PLAN.md`](./PLAN.md) for the full parameter-to-variable mapping for each tag instance.

---

## Migration Checklist

- [ ] Keep `hightouch-init.html` as a Custom HTML tag (do not replace)
- [ ] Import `hightouch-track.tpl`, `hightouch-pageview.tpl`, `hightouch-identify.tpl` into GTM
- [ ] Run unit tests for each template in the Template Editor
- [ ] Create tag instances and configure parameters (see `PLAN.md`)
- [ ] Validate in GTM Preview: confirm events fire with correct properties
- [ ] Confirm no `<script>` nodes accumulate across SPA navigations (DevTools → Elements)
- [ ] Pause original Custom HTML event tracking tags
- [ ] Publish container and monitor
- [ ] Delete original Custom HTML event tracking tags after validation window
