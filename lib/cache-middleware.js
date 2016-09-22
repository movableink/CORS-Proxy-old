// cacheMiddleware caches requests using the request URL as the key
//
// If a request is already in progress for the specified key, it will hold all other
// requests until the original finishes, then return the same response for all of them.
// This prevents the thundering herd problem, where many requests come in for a URL
// before any of them can be cached.

const crypto = require('crypto');
const responseBody = require('./response-body');

module.exports = function(cache) {
  return function cacheMiddleware(req, res, next) {
    const origin = (req.headers && req.headers.origin) || '*';

    let cacheKey = [req.method, req.url, origin];

    if (req.method === 'POST') {
      let bodyHash = crypto.createHash('md5').update(req.body || '').digest('hex');
      cacheKey.push(bodyHash);
    }

    if (cache.has(cacheKey)) {
      res.cacheStatus = 'hit';

      let result = cache.get(cacheKey);
      result.headers['x-cors-cache'] = res.cacheStatus;
      delete result.headers['date'];

      res.writeHead(result.statusCode, result.headers);
      res.end(result.body);

    } else if (cache.inFlight(cacheKey)) {
      res.cacheStatus = 'wait';
      res.setHeader('x-cors-cache', res.cacheStatus);

      cache.getLater(cacheKey, function(result) {
        // start over if cache key was abandoned
        if (result === null) {
          cache.log(`retry {${cacheKey}}`);
          return cacheMiddleware(req, res, next);
        }

        result.headers['x-cors-cache'] = res.cacheStatus;
        delete result.headers['date'];

        res.writeHead(result.statusCode, result.headers);
        res.end(result.body);
      });

    } else {
      res.cacheStatus = 'miss';
      res.setHeader('x-cors-cache', res.cacheStatus);

      cache.log(`locked {${cacheKey}}`);
      cache.lock(cacheKey);

      let getBody = responseBody.from(res);

      req.on('aborted', () => {
        cache.log(`abandoned {${cacheKey}}`);
        cache.abandon(cacheKey);
        res.aborted = true;
      });

      res.on('finish', () => {
        // client ended early, can't trust this response
        if (res.aborted) { return; }

        let result = {
          statusCode: res.statusCode,
          headers: res._headers,
          body: getBody()
        };

        let expires = parseInt(req.headers['x-reverse-proxy-ttl'], 10);
        expires = expires < 0 || !expires ? cache.expires : expires * 1000; // ms

        if (res.statusCode < 400) {
          cache.log(`set {${cacheKey}} expires in ${expires}ms`);
          cache.set(cacheKey, result, expires);
        } else {
          cache.log(`http error ${res.statusCode} on ${cacheKey}, not caching`);
        }

        cache.unlock(cacheKey, result);
        cache.log(`unlocked {${cacheKey}}`);
      });

      next();
    }
  };
};
