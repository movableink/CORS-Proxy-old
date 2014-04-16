http =          require 'http'
connect =       require 'connect'
url =           require 'url'
httpProxy =     require 'http-proxy'
honeybadger =   require './honeybadger'
Cache =         require './cache'
requestLogger = require './request_logger'
cors =          require './cors'

CACHE_TIME = 10 * 1000 # 10s
cache = new Cache(CACHE_TIME)

parseUrl = (requestUrl) ->
  [_, port] = (requestUrl.match(/^\/[^\/]+\:(\d+)/) || [])
  port = parseInt(port, 10) or 80
  proto = if port is 443 then 'https' else 'http'
  target = url.parse(requestUrl.replace(/^\//, "#{proto}://"))
  target.host = null
  target.port = null if port is 80 or port is 443

  {
    hostname: target.hostname
    path: target.path
    target: target.format()
  }

proxyServer = (req, res) ->
  proxyUrl = parseUrl req.url
  unless proxyUrl.hostname
    console.log "no hostname specified"
    res.writeHead(400, {})
    res.end("Bad request. (no hostname specified)");
    return

  cacheKey = [req.method, proxyUrl.target].join(':')

  if cache.has cacheKey
    res.cacheStatus = 'hit'
    result = cache.get cacheKey
    res.setHeader 'x-cors-proxy', 'cache hit'
    res.setHeader 'content-length', result.body.length
    res.writeHead result.statusCode, result.headers
    res.end result.body

  else if cache.inFlight cacheKey
    res.cacheStatus = 'wait'
    cache.getLater cacheKey, (result) ->
      res.setHeader 'x-cors-proxy', 'cache wait'
      res.setHeader 'content-length', result.body.length
      res.writeHead result.statusCode, result.headers
      res.end result.body

  else
    res.cacheStatus = 'miss'
    cache.lock cacheKey
    res.setHeader 'x-cors-proxy', 'cache miss'

    req.headers.host = proxyUrl.hostname

    proxy = httpProxy.createProxyServer()

    proxy.once 'proxyRes', (pres) ->
      responseBody = ''
      pres.setEncoding 'utf8'
      pres.on 'data', (chunk) -> responseBody += chunk

      pres.on 'end', ->
        result =
          statusCode: pres.statusCode
          headers: pres.headers
          body: responseBody

        expires = parseInt req.headers['x-reverse-proxy-ttl'], 10
        expires = if expires < 0 then null else expires * 1000 # ms

        if pres.statusCode < 400
          cache.set cacheKey, result, expires
        else
          console.log "error (#{pres.statusCode})"

        cache.unlock cacheKey, result

    # ugly hack because http-proxy will only use the original request's path
    originalUrl = req.url
    req.url = proxyUrl.target

    proxy.web req, res,
      target: proxyUrl.target
      secure: false
      headers:
        host: proxyUrl.hostname

    req.url = originalUrl

    proxy.on 'proxyError', (err, req, res) ->
      console.error err
      res.end 'Request failed.'

app = connect()
  .use(requestLogger())
  .use(cors())
  .use(proxyServer)

port = process.env.PORT || 9292
http.createServer(app).listen port

console.log "Listening on port #{port}"

process.on 'uncaughtException', (err) ->
  throw err unless server._handle

  console.error err
  server.close()
  honeybadger.notifyError err, {}, ->
    throw err
