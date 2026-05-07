/**
 * @name Calls gtmOnFailure and reports error when bridge not ready
 */
var errorReported = false;
mock('copyFromWindow', function(key) { return undefined; });
mock('callInWindow', function(fn) {
  if (fn === '_reportError') { errorReported = true; }
});

runCode({
  deviceId: 'device-abc',
  userId: 'user-123',
  email: 'user@example.com',
  sessionId: 'sess-xyz'
});

assertApi('gtmOnFailure').wasCalled();
