module.exports = function() {
  return function cors(req, res, next) {
    let headers;

    if (req.headers['access-control-request-headers']) {
      headers = req.headers['access-control-request-headers'];
    } else {
      headers = 'accept, accept-charset, accept-encoding, accept-language, authorization, content-length, content-type, host, origin, proxy-connection, referer, user-agent, x-requested-with';
      for (let header of Object.keys(req.headers)) {
        if (header.indexOf('x-') === 0) { headers += `, ${header}`; }
      }
    }

    let corsHeaders = {
      'access-control-allow-methods'     : 'HEAD, POST, GET, PUT, PATCH, DELETE',
      'access-control-max-age'           : '86400', // 24 hours
      'access-control-allow-headers'     : headers,
      'access-control-allow-credentials' : 'true',
      'access-control-allow-origin'      : req.headers.origin || "*",
      'access-control-expose-headers'    : 'x-cors-cache',
      'x-frame-options'                  : ''
    };

    for (let key of Object.keys(corsHeaders)) {
      res.setHeader(key, corsHeaders[key]);
    }

    if (req.method === 'OPTIONS') {
      res.end();
    } else {
      next();
    }
  };
};
