http =        require('http')
httpProxy =   require('http-proxy')
honeybadger = require('./honeybadger')
Cache =       require('./cache')

httpProxy.setMaxSockets(5000)

CACHE_TIME = 10 * 1000 # 10s
cache = new Cache(CACHE_TIME)

proxyServer = (req, res, proxy) ->
  start = new Date()

  req.headers.origin or= "*"

  if req.headers['access-control-request-headers']
    headers = req.headers['access-control-request-headers']
  else
    headers = 'accept, accept-charset, accept-encoding, accept-language, authorization, content-length, content-type, host, origin, proxy-connection, referer, user-agent, x-requested-with'
    headers += ", #{header}" for header in req.headers when req.indexOf('x-') is 0

  cors_headers =
    'access-control-allow-methods'     : 'HEAD, POST, GET, PUT, PATCH, DELETE'
    'access-control-max-age'           : '86400' # 24 hours
    'access-control-allow-headers'     : headers
    'access-control-allow-credentials' : 'true'
    'access-control-allow-origin'      : req.headers.origin


  if req.method is 'OPTIONS'
    console.log 'responding to OPTIONS request'
    res.writeHead(200, cors_headers);
    res.end();
    return

  else
    [ignore, hostname, path] = (req.url.match(/\/([^\/]+)(.*)/) || [])
    [host, port] = (hostname || "").split(/:/)

    unless host
      console.log "no hostname specified"
      res.writeHead(400, {})
      res.end("Bad request. (no hostname specified)");
      return

    res.setHeader(key, value) for key, value of cors_headers
    method = req.method

    cacheKey = [method, host, port, path].join(':')

    if cache.has cacheKey
      result = cache.get cacheKey
      res.setHeader 'x-cors-proxy', 'cache hit'
      res.setHeader 'content-length', result.body.length
      res.writeHead result.statusCode, result.headers
      console.log "cache hit length #{result.body.length}"
      res.end result.body

      reqTime = (new Date()) - start
      console.log "GET #{hostname}#{path} in #{reqTime} ms [CACHED]"

    else if cache.inFlight cacheKey
      cache.getLater cacheKey, (result) ->
        res.setHeader 'x-cors-proxy', 'cache wait'
        res.setHeader 'content-length', result.body.length
        res.writeHead result.statusCode, result.headers
        console.log "cache wait length #{result.body.length}"
        res.end result.body

        reqTime = (new Date()) - start
        console.log "GET #{hostname}#{path} in #{reqTime} ms [CACHE WAIT]"

    else
      cache.lock cacheKey
      res.setHeader 'x-cors-proxy', 'cache miss'

      req.headers.host = hostname
      req.url          = path

      proxy.target.https = (port == '443')

      proxy.once 'start', (preq, pres, target) ->
        cache.setupResponse pres

      proxy.once 'end', (preq, pres, presponse) ->
        result =
          statusCode: presponse.statusCode
          headers: presponse.headers
          body: pres.cacheData

        expires = parseInt req.headers['x-reverse-proxy-ttl'], 10
        expires = if expires < 0 then null else expires * 1000 # ms

        if presponse.statusCode < 400
          cache.set cacheKey, result, expires
        else
          console.log "error (#{presponse.statusCode})"

        cache.unlock cacheKey

        reqTime = (new Date()) - start
        console.log "GET #{hostname}#{path} in #{reqTime} ms [MISS]"

      proxy.proxyRequest(req, res, {
        host: host,
        changeOrigin: true,
        port: parseInt(port) || 80
      });

server = httpProxy.createServer(proxyServer)

server.proxy.on 'proxyError', (err, req, res) ->
  console.error err
  res.end 'Request failed.'

port = process.env.PORT || 9292
server.listen port

console.log "Listening on port #{port}"

process.on 'uncaughtException', (err) ->
  console.error err
  server.close()
  honeybadger.notifyError err, {}, ->
    process.exit 1
