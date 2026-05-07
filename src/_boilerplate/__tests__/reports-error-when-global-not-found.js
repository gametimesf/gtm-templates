/**
 * @name Calls gtmOnFailure and reports error when global not found on window
 */
var errorReported = false;
mock('copyFromWindow', function(key) { return undefined; });
mock('callInWindow', function(fn) {
  if (fn === '_reportError') { errorReported = true; }
});

runCode({
  myParam: 'test-value'
});

assertApi('gtmOnFailure').wasCalled();
