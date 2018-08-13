'use strict';

const http           = require('http');
const connect        = require('connect');
const bodyParser     = require('body-parser');
const Cache          = require('./lib/cache');
const headerValidity = require('./lib/header-validity');
const requestLogger  = require('./lib/request-logger');
const cors           = require('./lib/cors');
const proxy          = require('./lib/proxy');
const health         = require('./lib/health');
const statsReporter  = require('./lib/stats-reporter');
const stats          = require('./lib/report-stat');
const log            = require('./lib/log');

process.title = 'node (cors proxy)';

const CACHE_TIME = 10 * 1000; // 10s
let cache = new Cache(CACHE_TIME, {logging: false});

const app = connect()
  .use(headerValidity.checkHeaderValidity)
  .use(requestLogger())
  .use(stats())
  .use(health)
  .use(cors())
  .use(bodyParser.raw({type(req) { return req.method === 'POST'; }}))
  .use(cache.middleware())
  .use(proxy);

const port = process.env.PORT || 9292;
statsReporter.setup();
const server = http.createServer(app);

server.listen(port, () => {
  log({ listening: true, port: port });
});
