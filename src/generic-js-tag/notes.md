A single generic tag for third-party SDKs that follow a synchronous
fn(eventName, props) or fn(method, eventName, props) call pattern.

Prerequisite: Error Bridge Custom HTML tag must fire before this tag (All Pages, high priority).

NOT suitable for:
  - Async operations (Promises, crypto.subtle) — keep those as Custom HTML
  - SDKs that require DOM manipulation during the call

Adding a new vendor:
  GTM does not support wildcard permissions — each vendor's global must be
  explicitly declared in permissions.json. To add a new vendor:
  1. Add an entry to src/generic-js-tag/permissions.json
  2. If using dot notation (e.g. ttq.track), add two entries: root object (read only)
     and the method (execute only)
  3. Run npm run build
  4. Re-import dist/generic-js-tag.tpl into GTM and approve the new permission

Current vendors declared: fbq (Meta), spdt (Spotify), ttq (TikTok read), ttq.track (TikTok execute),
                          DD_RUM (Datadog), ire (Impact Radius), podscribe (Podscribe),
                          uetq (Microsoft Ads — raw), _uetqPush (Microsoft Ads — bridge)

Note: dot-notation calls (e.g. ttq.track) require a separate execute entry from the root
object read entry. Add both when registering a new nested method.
