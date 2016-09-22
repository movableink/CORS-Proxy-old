const stats = require('./stats-reporter');

module.exports = function() {
  return function statsReporter(req, res, next) {
    const start = new Date();

    res.on('finish', function() {
      const reqTime = (new Date()) - start;
      const cacheStatus = res.cacheStatus || 'miss';

      stats.add("requests", "1|c");
      stats.add(`cache_${cacheStatus}`, "1|c");
      stats.add(req.method, "1|c");
      stats.add("response_time", `${reqTime}|ms`);

      stats.send();
    }
    );

    next();
  };
};
