function () {
    var payload = {{Payload - Dynamic}};
    var result = {};
  
    for (var key in payload) {
      if (payload.hasOwnProperty(key)) {
          result['payload_' + key] = payload[key];
      }
    }
  
    return result;
  }