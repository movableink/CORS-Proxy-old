module.exports = ->
  return (req, res, next) ->
    if req.headers['access-control-request-headers']
      headers = req.headers['access-control-request-headers']
    else
      headers = 'accept, accept-charset, accept-encoding, accept-language, authorization, content-length, content-type, host, origin, proxy-connection, referer, user-agent, x-requested-with'
      headers += ", #{header}" for header of req.headers when header.indexOf('x-') is 0

    res.setHeader 'access-control-allow-methods', 'HEAD, POST, GET, PUT, PATCH, DELETE'
    res.setHeader 'access-control-max-age', '86400' # 24 hours
    res.setHeader 'access-control-allow-headers', headers
    res.setHeader 'access-control-allow-credentials', 'true'
    res.setHeader 'access-control-allow-origin', req.headers.origin or "*"
    res.setHeader 'access-control-expose-headers', 'x-cors-cache'
    res.setHeader 'x-frame-options', ''

    if req.method is 'OPTIONS'
      res.end()
    else
      next()
