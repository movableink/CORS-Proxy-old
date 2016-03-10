httpProxy     = require 'http-proxy'
parseUrl      = require './parse_url'

HEADERS = ['allow-origin', 'allow-headers', 'allow-credentials', 'allow-methods', 'max-age']

module.exports = (req, res) ->
  proxyUrl = parseUrl req.url

  unless proxyUrl.hostname
    console.log "no hostname specified"
    res.writeHead(400, {})
    res.end("Bad request. (no hostname specified)");
    return

  delete req.headers?['x-forwarded-proto']
  delete req.headers?['x-forwarded-for']

  proxy = httpProxy.createProxyServer()
  proxy.on 'error', (err, req, res) ->
    console.error err
    if !res.headersSent
      res.writeHead(500, {})
      res.end 'Request failed.'

  proxy.web req, res,
    target: proxyUrl.target
    secure: false
    headers:
      host: proxyUrl.hostname

  proxy.on 'proxyReq', (proxyReq) ->
    proxyReq.path = proxyUrl.path

  proxy.on 'proxyRes', (proxyRes) ->
    delete proxyRes?.headers?["access-control-#{name}"] for name in HEADERS
    delete proxyRes?.headers?['x-frame-options']
