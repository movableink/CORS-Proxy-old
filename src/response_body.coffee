# responseBody sets a 'body' property on the response, useful for caching
#
# Returns a function that, when called, returns the body.  Returns null if
# the request isn't yet complete.
#
# Example:
#
#  getBody = responseBody.from response
#  response.on 'finish', ->
#    console.log getBody()
#
# Parts are heavily influenced by the request module, by Mikeal Rogers

Buffer = require('buffer').Buffer

exports.from = (res) ->
  write = res.write.bind(res)
  end = res.end.bind(res)

  chunks = []
  bodyLength = 0
  body = null

  add = (data) ->
    chunks.push data
    bodyLength += data.length

  res.write = (data) ->
    add data
    write data

  res.end = (data) ->
    add data if data

    if chunks.length and Buffer.isBuffer(chunks[0])
      body = new Buffer(bodyLength)
      i = 0
      for chunk in chunks
        chunk.copy body, i, 0, chunk.length
        i += chunk.length
      body = body.toString(res.encoding) if res.encoding
    else if chunks.length
      if res.encoding is 'utf8' and chunks[0].length > 0 and chunks[0][0] is "\uFEFF"
        chunks[0] = chunks[0].substring(1)
      body = chunks.join ''
    else
      body = '' # no data

    end data

  return ->
    body