http          = require 'http'
connect       = require 'connect'
restreamer    = require 'connect-restreamer'
httpProxy     = require 'http-proxy'
honeybadger   = require './honeybadger'
Cache         = require './cache'
requestLogger = require './request_logger'
cors          = require './cors'
parseUrl      = require './parse_url'
rawBody       = require './raw_body'

HEADERS = ['allow-origin', 'allow-headers', 'allow-credentials', 'allow-methods', 'max-age']

CACHE_TIME = 10 * 1000 # 10s
cache = new Cache(CACHE_TIME, logging: false)

proxyServer = (req, res) ->
  proxyUrl = parseUrl req.url

  unless proxyUrl.hostname
    console.log "no hostname specified"
    res.writeHead(400, {})
    res.end("Bad request. (no hostname specified)");
    return

  proxy = httpProxy.createProxyServer()
  proxy.on 'error', (err, req, res) ->
    console.error err
    res.writeHead(500, {})
    res.end 'Request failed.'

  # ugly hack because http-proxy will only use the original request's path
  originalUrl = req.url
  req.url = proxyUrl.target

  proxy.web req, res,
    target: proxyUrl.target
    secure: false
    headers:
      host: proxyUrl.hostname

  proxy.on 'proxyRes', (proxyRes) ->
    delete proxyRes?.headers?["access-control-#{name}"] for name in HEADERS
    delete proxyRes?.headers?['x-frame-options']

  req.url = originalUrl

app = connect()
  .use(requestLogger())
  .use(cors())
  .use(rawBody())
  .use(restreamer(stringify: (x) -> x)) # rawBody eats the body and http-proxy can't deal
  .use(cache.middleware())
  .use(proxyServer)

port = process.env.PORT || 9292
server = http.createServer(app)
server.listen port

console.log "Listening on port #{port}"

process.on 'uncaughtException', (err) ->
  throw err unless server._handle

  console.error err
  server.close()
  honeybadger.notifyError err, {}, ->
    throw err
