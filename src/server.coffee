http          = require 'http'
connect       = require 'connect'
restreamer    = require 'connect-restreamer'
honeybadger   = require './honeybadger'
Cache         = require './cache'
requestLogger = require './request_logger'
cors          = require './cors'
rawBody       = require './raw_body'
proxy         = require './proxy'

process.title = 'node (CORS proxy)'

CACHE_TIME = 10 * 1000 # 10s
cache = new Cache(CACHE_TIME, logging: false)

app = connect()
  .use(requestLogger())
  .use(cors())
  .use(rawBody())
  .use(restreamer(stringify: (x) -> x)) # rawBody eats the body and http-proxy can't deal
  .use(cache.middleware())
  .use(proxy)

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
