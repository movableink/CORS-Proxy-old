http =      require('http')
httpProxy = require('http-proxy')

proxyServer = (req, res, proxy) ->

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

    console.log "proxying to #{hostname}#{path}"


    res.setHeader(key, value) for key, value of cors_headers

    req.headers.host = hostname
    req.url          = path

    proxy.target.https = (port == '443')

    # Put your custom server logic here, then proxy
    proxy.proxyRequest(req, res, {
      host: host,
      port: port || 80
    });

if process.env.NODE_ENV is "production"
  port = 80
else
  port = 9292

httpProxy.createServer(proxyServer).listen port
