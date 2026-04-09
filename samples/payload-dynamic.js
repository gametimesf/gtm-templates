function () {
    var dataPayload = {{getDataAnalyticsByKey}}('payload');
    var pagePayload = {{getPageDataByKey}}('payload');
  
    return  dataPayload || {{Payload}} || pagePayload;
  }