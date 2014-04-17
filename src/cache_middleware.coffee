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
      res.writeHead result.statusCode, result.headers
      res.end result.body

    else if cache.inFlight cacheKey
      res.cacheStatus = 'wait'
      res.setHeader 'x-cors-cache', res.cacheStatus

      cache.getLater cacheKey, (result) ->
        result.headers['x-cors-cache'] = res.cacheStatus
        res.writeHead result.statusCode, result.headers
        res.end result.body

    else
      res.cacheStatus = 'miss'
      res.setHeader 'x-cors-cache', res.cacheStatus

      cache.log "locked {#{cacheKey}}"
      cache.lock cacheKey

      write = res.write.bind(res)
      end = res.end.bind(res)

      res.cacheData = ''
      res.write = (data) ->
        res.cacheData += data.toString() if data
        write data

      res.end = (data) ->
        res.cacheData += data.toString() if data
        end data

      res.on 'finish', =>
        result =
          statusCode: res.statusCode
          headers: res._headers
          body: res.cacheData

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
