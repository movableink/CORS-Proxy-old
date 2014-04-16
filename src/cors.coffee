module.exports = ->
  return (req, res, next) ->
    if req.headers['access-control-request-headers']
      headers = req.headers['access-control-request-headers']
    else
      headers = 'accept, accept-charset, accept-encoding, accept-language, authorization, content-length, content-type, host, origin, proxy-connection, referer, user-agent, x-requested-with'
      headers += ", #{header}" for header of req.headers when header.indexOf('x-') is 0

    corsHeaders =
      'access-control-allow-methods'     : 'HEAD, POST, GET, PUT, PATCH, DELETE'
      'access-control-max-age'           : '86400' # 24 hours
      'access-control-allow-headers'     : headers
      'access-control-allow-credentials' : 'true'
      'access-control-allow-origin'      : req.headers.origin or "*"

    res.setHeader(key, value) for key, value of corsHeaders

    if req.method is 'OPTIONS'
      res.end()
    else
      next()