/**
 * @name Calls gtmOnFailure and reports error when DD_RUM not found
 */
var errorReported = false;
mock('copyFromWindow', function(key) { return undefined; });
mock('callInWindow', function(fn) {
  if (fn === '_reportError') { errorReported = true; }
});

runCode({
  method: 'addAction',
  actionName: 'Purchase',
  context: [],
  buildPayload: {}
});

assertApi('gtmOnFailure').wasCalled();
