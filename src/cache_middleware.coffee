# cacheMiddleware caches requests using the request URL as the key
#
# If a request is already in progress for the specified key, it will hold all other
# requests until the original finishes, then return the same response for all of them.
# This prevents the thundering herd problem, where many requests come in for a URL
# before any of them can be cached.

module.exports = (cache) ->
  return (req, res, next) ->
    cacheKey = [req.method, req.url]

    if cache.has cacheKey
      res.cacheStatus = 'hit'

      result = cache.get cacheKey
      result.headers['x-cors-cache'] = res.cacheStatus
      delete result.headers['date']
      res.writeHead result.statusCode, result.headers
      res.end result.body

    else if cache.inFlight cacheKey
      res.cacheStatus = 'wait'
      res.setHeader 'x-cors-cache', res.cacheStatus

      cache.getLater cacheKey, (result) ->
        result.headers['x-cors-cache'] = res.cacheStatus
        delete result.headers['date']
        res.writeHead result.statusCode, result.headers
        res.end result.body

    else
      res.cacheStatus = 'miss'
      res.setHeader 'x-cors-cache', res.cacheStatus

      cache.log "locked {#{cacheKey}}"
      cache.lock cacheKey

      write = res.write.bind(res)
      end = res.end.bind(res)

      chunks = []
      bodyLength = 0

      res.write = (data) ->
        chunks.push data
        bodyLength += data.length
        write data

      res.end = (data) ->
        if data
          chunks.push data
          bodyLength += data.length
        end data

      res.on 'finish', =>
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

        result =
          statusCode: res.statusCode
          headers: res._headers
          body: body

        expires = parseInt req.headers['x-reverse-proxy-ttl'], 10
        expires = if expires < 0 or not expires then cache.expires else expires * 1000 # ms

        if res.statusCode < 400
          cache.log "set {#{cacheKey}} expires in #{expires}ms"
          cache.set cacheKey, result, expires
        else
          cache.log "http error #{res.statusCode} on #{cacheKey}, not caching"

        cache.unlock cacheKey, result
        cache.log "unlocked {#{cacheKey}}"

      next()
