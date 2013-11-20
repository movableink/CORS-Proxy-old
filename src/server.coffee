http =      require('http')
httpProxy = require('http-proxy')
Cache =     require('./cache')

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

    cacheKey = [host, port, path].join(':')

    if cache.has cacheKey
      result = cache.get cacheKey
      res.writeHead result.statusCode, result.headers
      res.end result.body

      reqTime = (new Date()) - start
      console.log "GET #{hostname}#{path} in #{reqTime} ms [CACHED]"

    else if cache.inFlight cacheKey
      cache.getLater cacheKey, (result) ->
        res.writeHead result.statusCode, result.headers
        res.end result.body

        reqTime = (new Date()) - start
        console.log "GET #{hostname}#{path} in #{reqTime} ms [CACHE WAIT]"

    else
      cache.lock cacheKey

      req.headers.host = hostname
      req.url          = path

      proxy.target.https = (port == '443')

      proxy.once 'end', (preq, pres, presponse) ->
        result =
          statusCode: presponse.statusCode
          headers: presponse.headers
          body: presponse.body

        if presponse.statusCode < 400
          cache.set cacheKey, result

        cache.unlock cacheKey, result

        reqTime = (new Date()) - start
        console.log "GET #{hostname}#{path} in #{reqTime} ms [MISS]"

      # Put your custom server logic here, then proxy
      proxy.proxyRequest(req, res, {
        host: host,
        port: port || 80
      });

server = httpProxy.createServer(proxyServer)

server.proxy.on 'proxyError', (err, req, res) ->
  console.error err
  res.end 'Request failed.'

port = process.env.PORT || 9292
server.listen port

console.log "Listening on port #{port}"
