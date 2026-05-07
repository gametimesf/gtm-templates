/**
 * @name Calls fn(methodArg, eventName, props) when methodArg is set
 */
var calledWith = {};
mock('copyFromWindow', function(key) {
  if (key === 'fbq') { return function() {}; }
});
mock('callInWindow', function(fn, a, b, c) {
  calledWith = { fn: fn, method: a, eventName: b, props: c };
});

runCode({
  windowFunction: 'fbq',
  methodArg: 'track',
  eventName: 'ViewContent',
  properties: [{ key: 'content_ids', value: 'evt-456' }],
  buildPayload: {}
});

assertApi('gtmOnSuccess').wasCalled();
