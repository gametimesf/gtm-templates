/**
 * @name Calls myGlobal with expected arguments
 */
var calledWith = {};
mock('copyFromWindow', function(key) {
  if (key === 'myGlobal') { return function() {}; }
});
mock('callInWindow', function(fn, arg) {
  calledWith = { fn: fn, arg: arg };
});

runCode({
  myParam: 'test-value'
});

assertApi('gtmOnSuccess').wasCalled();
