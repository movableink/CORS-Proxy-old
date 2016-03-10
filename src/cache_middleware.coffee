# cacheMiddleware caches requests using the request URL as the key
#
# If a request is already in progress for the specified key, it will hold all other
# requests until the original finishes, then return the same response for all of them.
# This prevents the thundering herd problem, where many requests come in for a URL
# before any of them can be cached.

crypto         = require 'crypto'
responseBody   = require './response_body'
getRequestBody = require 'raw-body'

module.exports = (cache) ->
  return cacheMiddleware = (req, res, next) ->
    origin = req.headers?.origin || '*'
    if req.method is 'POST'
      bodyHash = crypto.createHash('md5').update(req.body or '').digest('hex')
      cacheKey = [req.method, req.url, origin, bodyHash]
    else
      cacheKey = [req.method, req.url, origin]

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
        # start over if cache key was abandoned
        if result is null
          cache.log "retry {#{cacheKey}}"
          return cacheMiddleware(req, res, next)

        result.headers['x-cors-cache'] = res.cacheStatus
        delete result.headers['date']
        res.writeHead result.statusCode, result.headers
        res.end result.body

    else
      res.cacheStatus = 'miss'
      res.setHeader 'x-cors-cache', res.cacheStatus

      cache.log "locked {#{cacheKey}}"
      cache.lock cacheKey

      getBody = responseBody.from res

      req.on 'aborted', =>
        cache.log "abandoned {#{cacheKey}}"
        cache.abandon cacheKey
        res.aborted = true

      res.on 'finish', =>
        # client ended early, can't trust this response
        return if res.aborted

        result =
          statusCode: res.statusCode
          headers: res._headers
          body: getBody()

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
