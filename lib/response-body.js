'use strict';

// responseBody sets a 'body' property on the response, useful for caching
//
// Returns a function that, when called, returns the body.  Returns null if
// the request isn't yet complete.
//
// Example:
//
//  getBody = responseBody.from response
//  response.on 'finish', ->
//    console.log getBody()
//
// Parts are heavily influenced by the request module, by Mikeal Rogers

const Buffer = require('buffer').Buffer;

exports.from = function from(res) {
  const write = res.write.bind(res);
  const end = res.end.bind(res);

  let chunks = [];
  let bodyLength = 0;
  let body = null;

  let add = function(data) {
    chunks.push(data);
    bodyLength += data.length;
  };

  res.write = function(data) {
    add(data);
    write(data);
  };

  res.end = function(data) {
    if (data) { add(data); }

    if (chunks.length && Buffer.isBuffer(chunks[0])) {
      body = new Buffer(bodyLength);

      let i = 0;
      chunks.forEach((chunk) => {
        chunk.copy(body, i, 0, chunk.length);
        i += chunk.length;
      });

      if (res.encoding) { body = body.toString(res.encoding); }
    } else if (chunks.length) {
      if (res.encoding === 'utf8'
          && chunks[0].length > 0
          && chunks[0][0] === "\uFEFF") {
        chunks[0] = chunks[0].substring(1);
      }
      body = chunks.join('');
    } else {
      body = ''; // no data
    }

    end(data);
  };

  return () => body;
};
