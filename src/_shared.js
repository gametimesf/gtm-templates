// Injected into every template at build time.
// reportError forwards to window._reportError (set by the Error Bridge Custom HTML tag).
// callInWindow silently no-ops if _reportError is not yet on window.
function reportError(message, ctx) {
  require('callInWindow')('_reportError', message, ctx);
}
