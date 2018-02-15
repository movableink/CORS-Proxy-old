'use strict';

const httpProxy = require('http-proxy');
const parseUrl = require('./parse-url');
const log = require('./log');
const http = require('http');
const https = require('https');

const agentOptions = {
  maxSockets: 62000,
  keepAlive: true,
  maxFreeSockets: 1000,
  keepAliveMsecs: 100,
  timeout: 15000
};

const httpAgent = new http.Agent(agentOptions);
const httpsAgent = new https.Agent(agentOptions);

const corsHeaders = ['allow-origin', 'allow-headers', 'allow-credentials', 'allow-methods', 'max-age'];

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
    delete req.headers['cookie'];
    delete req.headers['expect'];
  }

  req.headers['connection'] = 'keep-alive';

  let agent = proxyUrl.isHttps ? httpsAgent : httpAgent;
  let proxy = httpProxy.createProxyServer({ agent: agent });

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
      if(proxyRes.statusCode > 999 || proxyRes.statusCode <= 0) {
        proxyRes.statusCode = 500;
      }
      delete proxyRes.headers['x-frame-options'];
      corsHeaders.forEach((name) => {
        delete proxyRes.headers[`access-control-${name}`];
      });
    }
  });
};
