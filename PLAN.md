# Plan: GTM Custom Templates for Hightouch Analytics

## Context
Custom HTML tags in GTM inject a `<script>` element into the DOM every time they fire. In SPAs where tags re-fire on route changes, these accumulate and bloat the DOM. GTM **Custom Templates** execute Sandboxed JavaScript without any DOM injection — converting the existing Custom HTML tags into `.tpl` templates eliminates the bloat entirely.

---

## Architecture: 4 Templates

Each Hightouch SDK method gets its own template because their parameter sets and call signatures differ:

| Template | SDK Method | Replaces |
|---|---|---|
| `hightouch-init.tpl` | SDK load + `htevents` stub setup | `hightouch-init.html` |
| `hightouch-track.tpl` | `htevents.track(eventName, props)` | `hightouch-catchall.html`, `hightouch-click.html` |
| `hightouch-pageview.tpl` | `htevents.page(pageType, title, props)` | `hightouch-pageview.html` |
| `hightouch-identify.tpl` | `htevents.setAnonymousId()` + `htevents.identify(userId, traits)` | `hightouch-identify.html` |

The `hightouch-track.js` variable is not needed as a separate template — its logic moves into the Sandboxed JS of `hightouch-track.tpl`.

**Important:** `{{CJ - Base Properties}}` and `{{CJ - Build Payload}}` remain as GTM Custom JavaScript variables. Templates receive their **return values** as pre-computed objects — the template parameters simply point to those existing variables. No re-implementation of their logic is needed.

`cj-base-properties.js` has a try-catch that returns `undefined` on error (catch block has no return), so the `|| {}` fallback in templates is important.

---

## Sandboxed JS API Substitutions

| Original | Sandboxed JS Replacement |
|---|---|
| `typeof htevents === 'undefined'` | `require('copyFromWindow')('htevents')` |
| `Object.assign(...)` | `require('Object.assign')(...)` |
| `console.error(...)` | `require('logToConsole').error(...)` |
| `console.log(...)` | `require('logToConsole').log(...)` |
| implicit IIFE completion | `data.gtmOnSuccess()` / `data.gtmOnFailure()` |

---

## File Structure

```
templates/
  hightouch-init.tpl
  hightouch-track.tpl
  hightouch-pageview.tpl
  hightouch-identify.tpl
```

---

## Template 1: `hightouch-init.tpl`

**Why this still eliminates DOM bloat:** The Custom HTML init tag wraps all the stub setup code in a `<script>` block that stays in the DOM. The template's Sandboxed JS runs the same logic without a DOM node. The SDK itself is loaded via GTM's `injectScript` API, which uses caching (`cacheKey`) to guarantee a single load — not a new `<script>` per tag fire.

**Parameters:**

| Key | GTM Variable | Notes |
|---|---|---|
| `environment` | `{{ENV}}` | Used to select API key |
| `prodApiKey` | `{{Hightouch - API Key [PROD]}}` | Used when env = `production` |
| `devApiKey` | `{{Hightouch - API Key}}` | Used otherwise |
| `apiHost` | `{{Hightouch - API Host}}` | Passed as `{ apiHost }` to the SDK |

**Sandboxed JS:**
```javascript
var copyFromWindow = require('copyFromWindow');
var setInWindow = require('setInWindow');
var injectScript = require('injectScript');
var logToConsole = require('logToConsole');

// Guard against double-init
var existing = copyFromWindow('htevents');
if (existing && existing.invoked) {
  logToConsole.error('Hightouch snippet included twice.');
  data.gtmOnSuccess();
  return;
}

// Set up the htevents queuing stub (mirrors the minified snippet)
setInWindow('htevents', existing || [], false);
var e = copyFromWindow('htevents');

e.invoked = true;
e.methods = [
  'trackSubmit','trackClick','trackLink','trackForm','pageview',
  'identify','reset','group','track','ready','alias','debug',
  'page','once','off','on','addSourceMiddleware',
  'addIntegrationMiddleware','setAnonymousId','addDestinationMiddleware'
];

// Factory: each stub method queues calls until the real SDK replaces them
e.factory = function(methodName) {
  return function() {
    var args = [];
    for (var i = 0; i < arguments.length; i++) { args.push(arguments[i]); }
    args.unshift(methodName);
    e.push(args);
    return e;
  };
};
for (var i = 0; i < e.methods.length; i++) {
  e[e.methods[i]] = e.factory(e.methods[i]);
}

e.SNIPPET_VERSION = '0.0.1';
e._writeKey = data.environment === 'production' ? data.prodApiKey : data.devApiKey;
e._loadOptions = { apiHost: data.apiHost };

// Load SDK — cacheKey prevents duplicate script loads on SPA navigations
var sdkUrl = 'https://cdn.hightouch-events.com/browser/release/v1-latest/events.min.js';
injectScript(sdkUrl, function() {
  e.page();
  data.gtmOnSuccess();
}, data.gtmOnFailure, sdkUrl);
```

---

## Template 2: `hightouch-track.tpl`

**Parameters:**

| Key | GTM Variable | Notes |
|---|---|---|
| `eventName` | `{{Event}}` or `'click'` | Required |
| `interaction` | `{{CJ - Dynamic - Interaction}}` | Optional |
| `sourcePageType` | `{{CJ - Page Source}}` | Optional |
| `targetPageType` | `{{DLV - Target Page}}` | Optional, click only |
| `searchSessionId` | `{{DLV - Search Session ID}}` | Optional, catchall only |
| `searchTerm` | `{{DLV - Search Term}}` | Optional, catchall only |
| `baseProperties` | `{{CJ - Base Properties}}` | Object |
| `buildPayload` | `{{CJ - Build Payload}}` | Object |

**Sandboxed JS:**
```javascript
var copyFromWindow = require('copyFromWindow');
var objectAssign = require('Object.assign');
var logToConsole = require('logToConsole');

var htevents = copyFromWindow('htevents');
if (!htevents) { data.gtmOnFailure(); return; }

var eventProperties = {};
if (data.interaction !== undefined)     eventProperties.interaction = data.interaction;
if (data.sourcePageType !== undefined)  eventProperties.source_page_type = data.sourcePageType;
if (data.targetPageType !== undefined)  eventProperties.target_page_type = data.targetPageType;
if (data.searchSessionId !== undefined) eventProperties.search_session_id = data.searchSessionId;
if (data.searchTerm !== undefined)      eventProperties.search_term = data.searchTerm;

var properties = objectAssign({}, data.baseProperties || {}, eventProperties, data.buildPayload || {});

try {
  htevents.track(data.eventName, properties);
  data.gtmOnSuccess();
} catch (error) {
  logToConsole.error('Could not fire Hightouch ' + data.eventName + ' event', error);
  data.gtmOnFailure();
}
```

**Tag migration mapping:**

| Use case | eventName | Extra params | Leave blank |
|---|---|---|---|
| Catchall | `{{Event}}` | interaction, sourcePageType, searchSessionId, searchTerm | targetPageType |
| Click | `click` | interaction, sourcePageType, targetPageType | searchSessionId, searchTerm |

---

## Template 3: `hightouch-pageview.tpl`

**Parameters:**

| Key | GTM Variable | Notes |
|---|---|---|
| `pageType` | `{{CJ - Dynamic - Page Type}}` | First arg to `htevents.page()` |
| `pageTitle` | `{{JavaScript - Page Title}}` | Second arg to `htevents.page()` |
| `mode` | `{{CJ - Mode}}` | Optional |
| `promoCode` | `{{CJ - Dynamic - Promo Code}}` | Optional |
| `status` | `{{DLV - Status}}` | Optional |
| `baseProperties` | `{{CJ - Base Properties}}` | Object |
| `buildPayload` | `{{CJ - Build Payload}}` | Object |

**Sandboxed JS:**
```javascript
var copyFromWindow = require('copyFromWindow');
var objectAssign = require('Object.assign');
var logToConsole = require('logToConsole');

var htevents = copyFromWindow('htevents');
if (!htevents) { data.gtmOnFailure(); return; }

var eventProperties = {
  mode: data.mode,
  promo_code: data.promoCode,
  status: data.status
};

var properties = objectAssign({}, data.baseProperties || {}, eventProperties, data.buildPayload || {});

try {
  htevents.page(data.pageType, data.pageTitle, properties);
  data.gtmOnSuccess();
} catch (error) {
  logToConsole.error("Could not fire Hightouch 'Page View' event", error);
  data.gtmOnFailure();
}
```

---

## Template 4: `hightouch-identify.tpl`

**Parameters:**

| Key | GTM Variable | Notes |
|---|---|---|
| `deviceId` | `{{Device ID}}` | Used as anonymousId |
| `userId` | `{{CJ - User ID}}` | Primary userId |
| `userIdFallback` | `{{Cookie - gt_id}}` | Fallback if userId is falsy |
| `email` | `{{DLV - User Email}}` | Trait |
| `phone` | `{{DLV - User Phone}}` | Trait |
| `sessionId` | `{{Cookie - gt_sid}}` | Trait |

**Sandboxed JS:**
```javascript
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

var htevents = copyFromWindow('htevents');
if (!htevents) {
  logToConsole.log('htevents undefined');
  data.gtmOnFailure();
  return;
}

htevents.setAnonymousId(data.deviceId);

var userId = data.userId || data.userIdFallback;
var traits = {
  email: data.email,
  phone: data.phone,
  deviceId: data.deviceId,
  sessionId: data.sessionId
};

try {
  htevents.identify(userId, traits);
  data.gtmOnSuccess();
} catch (error) {
  logToConsole.error("Could not fire Hightouch 'Identify' event", error);
  data.gtmOnFailure();
}
```

---

## Unit Tests (per template)

Each template includes 3 tests runnable in the GTM Template Editor:
1. **Happy path** — `htevents` present, method called → `gtmOnSuccess` called
2. **Missing htevents** — `copyFromWindow` returns undefined → `gtmOnFailure` called
3. **Method throws** — `htevents.[method]` throws → `gtmOnFailure` called

---

## GTM Import & Migration Steps

1. Import each `.tpl` into GTM: Tags → New → Import (start with `hightouch-init.tpl`)
2. Run built-in unit tests in Template Editor for each template
3. Create tag instances using the variable mappings in each template's Notes section:
   - Init: one instance, fires on All Pages
   - Track: one instance per event type (catchall, click) per migration table above
   - Pageview: one instance
   - Identify: one instance
4. Test in GTM Preview:
   - Confirm correct events fire with expected properties
   - Confirm no `<script>` nodes accumulate in DOM across SPA navigations (DevTools → Elements → filter for `script`)
   - Confirm init fires SDK load only once even on repeated route changes
5. Pause (don't delete) original Custom HTML tags, publish, observe
6. Delete original Custom HTML tags after validation window
