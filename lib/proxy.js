const httpProxy = require('http-proxy');
const parseUrl = require('./parse-url');
const log = require('./log');

let corsHeaders = ['allow-origin', 'allow-headers', 'allow-credentials', 'allow-methods', 'max-age'];

module.exports = function proxy(req, res) {
  const proxyUrl = parseUrl(req.url);

  if (!proxyUrl.hostname) {
    log({
      proxyError: "bad request",
      detail:     "no hostname specified"
    });

    res.writeHead(400, {});
    res.end("Bad request. (no hostname specified)");
    return;
  }

  if (req.headers) {
    delete req.headers['x-forwarded-proto'];
    delete req.headers['x-forwarded-for'];
    delete req.headers['x-mi-cbe'];
  }

  let proxy = httpProxy.createProxyServer();
  proxy.on('error', function(err, req, res) {
    log({
      proxyError: "error event",
      detail:     err
    });

    if (!res.headersSent) {
      res.writeHead(500, {});
      res.end('Request failed.');
    }
  }
  );

  proxy.web(req, res, {
    target: proxyUrl.target,
    secure: false,
    proxyTimeout: 30000,
    headers: {
      host: proxyUrl.hostname
    }
  });

  proxy.on('econnreset', function(err, req, res, target) {
    log({
      proxyError: "connection reset",
      detail: err,
      target: target
    });
  });

  proxy.on('proxyReq', function(proxyReq, req) {
    proxyReq.path = proxyUrl.path;
    if (req.method === "POST" && req.body) {
      proxyReq.write(req.body);
    }
  });

  proxy.on('proxyRes', function(proxyRes) {
    if (proxyRes && proxyRes.headers) {
      delete proxyRes.headers['x-frame-options'];
      corsHeaders.forEach((name) => {
        delete proxyRes.headers[`access-control-${name}`];
      });
    }
  });
};
