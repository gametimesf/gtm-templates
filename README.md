# GTM Hightouch Custom Templates

GTM Custom Template replacements for Hightouch analytics tags. Eliminates DOM bloat caused by Custom HTML tags in Single Page Applications.

---

## The Problem

Google Tag Manager's **Custom HTML** tag type works by injecting a `<script>` element into the DOM each time the tag fires. In a traditional multi-page site this is a non-issue — the DOM is destroyed on every navigation. In a **Single Page Application (SPA)**, the DOM persists across route changes, so every tag fire appends another `<script>` node. Over a browsing session, hundreds of orphaned script elements accumulate, degrading performance and making the DOM harder to debug.

---

## The Solution

GTM **Custom Templates** use Sandboxed JavaScript — a restricted execution environment that runs tag logic directly without creating any DOM nodes. The result is functionally identical analytics tracking with zero DOM pollution, regardless of how many times a tag fires.

---

## What's in This Repo

```
templates/        GTM Custom Template .tpl files ready to import
PLAN.md           Full implementation plan with parameter mappings and migration notes
```

### Templates

| File | Replaces | Hightouch SDK Call |
|---|---|---|
| `hightouch-init.tpl` | `hightouch-init.html` | Stub setup + SDK load via `injectScript` |
| `hightouch-track.tpl` | `hightouch-catchall.html`, `hightouch-click.html` | `htevents.track(eventName, props)` |
| `hightouch-pageview.tpl` | `hightouch-pageview.html` | `htevents.page(pageType, title, props)` |
| `hightouch-identify.tpl` | `hightouch-identify.html` | `htevents.setAnonymousId()` + `htevents.identify(userId, traits)` |

---

## Advantages of Sandboxed JS over Custom HTML

### 1. No DOM Bloat
Custom HTML tags inject a `<script>` element every time they fire. Templates execute in GTM's sandboxed runtime — no DOM nodes are created or left behind. On a typical SPA session with dozens of route changes, this can mean the difference between hundreds of orphaned script elements and zero.

### 2. Single SDK Load via `injectScript` Caching
The init template uses GTM's `injectScript` API with a `cacheKey`. GTM tracks which URLs have already been loaded and skips re-fetching if the same key has been seen — even if the init tag fires again on an SPA route change. Custom HTML has no such mechanism; the SDK `<script>` element would be inserted again each time.

### 3. Proper Tag Sequencing via `gtmOnSuccess` / `gtmOnFailure`
Custom HTML tags have no native way to signal completion or failure to GTM. Templates call `data.gtmOnSuccess()` or `data.gtmOnFailure()`, which integrates correctly with GTM's tag sequencing (setup/cleanup tags) and built-in exception alerting. If `htevents` is missing or `track()` throws, the failure is surfaced to GTM's monitoring rather than silently swallowed.

### 4. Built-in Unit Testing
The GTM Template Editor includes a unit test runner. Each template ships with three tests covering the happy path, missing `htevents`, and method exceptions. These run inside GTM before any container publish — no external test framework or build step needed.

### 5. Controlled Permissions Model
Sandboxed JS templates declare exactly which browser APIs they need (e.g. `copyFromWindow`, `injectScript`, `setInWindow`). GTM enforces these permissions at import time and surfaces them to reviewers in the template UI. Custom HTML tags have unrestricted access to the full browser API with no visibility into what they actually use.

### 6. Reusable, Parameterised Tags
Each template exposes a set of typed parameters with help text and validation. A single `hightouch-track.tpl` covers both the catchall and click use cases — the difference is just parameter configuration per tag instance. Adding a new event type requires a new tag instance, not a new copy-pasted HTML file.

---

## Sandboxed JS API Reference

The following substitutions are used throughout the templates. Native browser globals are not available in Sandboxed JS — GTM provides purpose-built equivalents via `require()`.

| Standard JS | Sandboxed JS Equivalent |
|---|---|
| `window.htevents` | `require('copyFromWindow')('htevents')` |
| `window.htevents = value` | `require('setInWindow')('htevents', value)` |
| `Object.assign(...)` | `require('Object.assign')(...)` |
| `console.log(...)` | `require('logToConsole').log(...)` |
| `console.error(...)` | `require('logToConsole').error(...)` |
| Script tag injection | `require('injectScript')(url, onSuccess, onFailure, cacheKey)` |
| Tag completion signal | `data.gtmOnSuccess()` / `data.gtmOnFailure()` |

---

## Importing into GTM

1. In GTM, go to **Templates → Tag Templates → New**
2. Click the menu (⋮) → **Import**
3. Select a `.tpl` file from the `templates/` directory
4. Review the permissions GTM surfaces, then click **Save**
5. Repeat for each template — start with `hightouch-init.tpl`

Run the built-in **unit tests** (Templates editor → Run Tests) for each template before creating tag instances.

See [`PLAN.md`](./PLAN.md) for the full parameter-to-variable mapping for each tag instance.

---

## Migration Checklist

- [ ] Import all 4 `.tpl` files into GTM
- [ ] Run unit tests for each template in the Template Editor
- [ ] Create tag instances and configure parameters (see `PLAN.md`)
- [ ] Validate in GTM Preview: confirm events fire with correct properties
- [ ] Confirm no `<script>` nodes accumulate across SPA navigations (DevTools → Elements)
- [ ] Pause original Custom HTML tags
- [ ] Publish container and monitor
- [ ] Delete original Custom HTML tags after validation window
