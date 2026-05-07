/**
 * @name Fires setUser with context object
 */
var calledWith = {};
mock('copyFromWindow', function(key) {
  if (key === 'DD_RUM') { return {}; }
});
mock('callInWindow', function(fn, ctx) {
  calledWith = { fn: fn, ctx: ctx };
});

runCode({
  method: 'setUser',
  context: [{ key: 'id', value: 'user-123' }],
  buildPayload: {}
});

assertApi('gtmOnSuccess').wasCalled();
