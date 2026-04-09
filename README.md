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
samples/          Original Custom HTML tags and variable scripts (reference only)
templates/        GTM Custom Template .tpl files ready to import
PLAN.md           Full implementation plan with parameter mappings and migration notes
```

### Templates

| File | Replaces | Hightouch SDK Call |
|---|---|---|
| `hightouch-track.tpl` | `hightouch-catchall.html`, `hightouch-click.html` | `htevents.track(eventName, props)` |
| `hightouch-pageview.tpl` | `hightouch-pageview.html` | `htevents.page(pageType, title, props)` |
| `hightouch-identify.tpl` | `hightouch-identify.html` | `htevents.setAnonymousId()` + `htevents.identify(userId, traits)` |

> `hightouch-init.tpl` is included in `templates/` for reference but should not be used — keep `hightouch-init.html` as a Custom HTML tag.

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
| `Object.assign(...)` | inline `for...in` loop |
| `console.log(...)` | `require('logToConsole')(...)` |
| Tag completion signal | `data.gtmOnSuccess()` / `data.gtmOnFailure()` |

---

## Importing into GTM

1. In GTM, go to **Templates → Tag Templates → New**
2. Click the menu (⋮) → **Import**
3. Select a `.tpl` file from the `templates/` directory
4. Review the permissions GTM surfaces, then click **Save**
5. Repeat for the three event tracking templates

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
