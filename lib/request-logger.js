const log = require('./log');

module.exports = function() {
  return function requestLogger(req, res, next) {
    let start = new Date();

    res.on('finish', function() {
      const reqTime = (new Date()) - start;
      const cacheStatus = res.cacheStatus || 'miss';

      log({
        statusCode: res.statusCode,
        method: req.method,
        url: req.url,
        time: reqTime,
        cacheStatus: cacheStatus,
        headers: req.headers
      });
    }
    );

    res.on('close', function() {
      const reqTime = (new Date()) - start;
      const cacheStatus = res.cacheStatus || 'miss';

      log({
        statusCode: res.statusCode,
        method: req.method,
        url: req.url,
        time: reqTime,
        cacheStatus: cacheStatus,
        headers: req.headers
      });
    }
    );

    next();
  };
};
