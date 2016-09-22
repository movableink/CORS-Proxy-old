module.exports = function() {
  return function requestLogger(req, res, next) {
    let start = new Date();

    res.on('finish', function() {
      const reqTime = (new Date()) - start;
      const cacheStatus = res.cacheStatus || 'miss';
      console.log(`${new Date().toISOString()} ${res.statusCode} ${req.method} ${req.url} in ${reqTime} ms (cache ${cacheStatus}) ${JSON.stringify(req.headers)}`);
    }
    );

    res.on('close', function() {
      const reqTime = (new Date()) - start;
      const cacheStatus = res.cacheStatus || 'miss';
      console.log(`${new Date().toISOString()} ${res.statusCode} ${req.method} ${req.url} in ${reqTime} ms (cache ${cacheStatus} ABORTED) ${JSON.stringify(req.headers)}`);
    }
    );

    next();
  };
};
