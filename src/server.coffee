http          = require 'http'
connect       = require 'connect'
restreamer    = require 'connect-restreamer'
Cache         = require './cache'
requestLogger = require './request_logger'
cors          = require './cors'
rawBody       = require './raw_body'
proxy         = require './proxy'
health        = require './health'
statsReporter = require("./stats_reporter")
stats         = require './report_stats'

process.title = 'node (cors proxy)'

CACHE_TIME = 10 * 1000 # 10s
cache = new Cache(CACHE_TIME, logging: false)

app = connect()
  .use(requestLogger())
  .use(stats())
  .use(health)
  .use(cors())
  .use(rawBody())
  .use(restreamer(stringify: (x) -> x)) # rawBody eats the body and http-proxy can't deal
  .use(cache.middleware())
  .use(proxy)

port = process.env.PORT || 9292
statsReporter.setup()
server = http.createServer(app)
server.listen port

console.log "Listening on port #{port}"
