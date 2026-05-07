/**
 * @name Calls gtmOnFailure and reports error when bridge not ready
 */
var errorReported = false;
mock('copyFromWindow', function(key) { return undefined; });
mock('callInWindow', function(fn) {
  if (fn === '_reportError') { errorReported = true; }
});

runCode({
  pageType: 'pdp',
  pageTitle: 'Event Detail',
  baseProperties: {},
  buildPayload: {}
});

assertApi('gtmOnFailure').wasCalled();
