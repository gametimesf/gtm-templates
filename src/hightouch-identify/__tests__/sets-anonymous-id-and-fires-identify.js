/**
 * @name Sets anonymous ID and fires identify with traits via bridge functions
 */
var anonIdSet, identifyCalledWith;
mock('copyFromWindow', function(key) {
  if (key === '_htIdentify') { return function() {}; }
});
mock('callInWindow', function(fn, a, b) {
  if (fn === '_htSetAnonId') { anonIdSet = a; }
  if (fn === '_htIdentify') { identifyCalledWith = { userId: a, traits: b }; }
});

runCode({
  deviceId: 'device-abc',
  userId: 'user-123',
  email: 'user@example.com',
  phone: '+15551234567',
  sessionId: 'sess-xyz'
});

assertApi('gtmOnSuccess').wasCalled();
