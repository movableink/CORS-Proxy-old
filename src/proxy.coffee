http          = require 'http'
https         = require 'https'
httpProxy     = require 'http-proxy'
parseUrl      = require './parse_url'

HEADERS = ['allow-origin', 'allow-headers', 'allow-credentials', 'allow-methods', 'max-age']

agentOptions =
  maxSockets: 62000
  keepAlive: true
  maxFreeSockets: 1000
  keepAliveMsecs: 100
  timeout: 15000

httpAgent = new http.Agent(agentOptions)
httpsAgent = new https.Agent(agentOptions)

module.exports = (req, res) ->
  proxyUrl = parseUrl req.url

  unless proxyUrl.hostname
    console.log JSON.stringify(
      date: new Date().toISOString()
      proxyError: "bad request"
      detail:     "no hostname specified"
    )
    res.writeHead(400, {})
    res.end("Bad request. (no hostname specified)");
    return

  delete req.headers?['x-forwarded-proto']
  delete req.headers?['x-forwarded-for']
  delete req.headers?['x-mi-cbe']

  req.headers['connection'] = 'keep-alive'

  agent = if proxyUrl.isHttps then httpsAgent else httpAgent;

  proxy = httpProxy.createProxyServer(agent: agent)
  proxy.on 'error', (err, req, res) ->
    console.error JSON.stringify(
      date: new Date().toISOString()
      proxyError: "error event"
      detail:     err
    )
    if !res.headersSent
      res.writeHead(500, {})
      res.end 'Request failed.'

  proxy.web req, res,
    target: proxyUrl.target
    secure: false
    proxyTimeout: 30000
    headers:
      host: proxyUrl.hostname

  proxy.on 'proxyReq', (proxyReq, req) ->
    proxyReq.path = proxyUrl.path
    proxyReq.write(req.body) if (req.method=="POST" && req.body)


  proxy.on 'proxyRes', (proxyRes) ->
    delete proxyRes?.headers?["access-control-#{name}"] for name in HEADERS
    delete proxyRes?.headers?['x-frame-options']
