/**
 * @name Calls gtmOnFailure and reports error when root function not found on window
 */
var errorReported = false;
mock('copyFromWindow', function(key) { return undefined; });
mock('callInWindow', function(fn) {
  if (fn === '_reportError') { errorReported = true; }
});

runCode({
  windowFunction: 'spdt',
  eventName: 'viewProduct',
  properties: [],
  buildPayload: {}
});

assertApi('gtmOnFailure').wasCalled();
