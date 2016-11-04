const lynx = require('lynx');
const dns = require('dns');
const os = require('os');

const log = require('./log');

class StatsReporter {
  constructor() {
    this.clear();
  }

  clear() {
    this._stats = {};
  }

  client() {
    return this._client;
  }

  stats() {
    return this._stats;
  }

  add(key, value) {
    this._stats[key] = value;
  }

  errorHandler(err) {
    log({
      statsReporting: false,
      error: err
    });
  }

  send() {
    if (!this._client) { return; }

    let fullStats = {};
    for (let stat in this._stats) {
      let value = this._stats[stat];
      fullStats[`${this._prefix}.${stat}`] = value;
    }

    this._client.send(fullStats);
    this.clear();
  }

  setup(callback) {
    const hostname = os.hostname().split('.')[0];
    const dc = process.env.DATACENTER || "main";

    const statsd_host = process.env.STATSD_HOST   || "localhost";
    const statsd_port = process.env.STATSD_PORT   || 8125;
    this._prefix    = process.env.STATSD_PREFIX || `cors.${dc}.${hostname}`;

    log({
      statsReporting: true,
      host: statsd_host,
      port: statsd_port,
      prefix: this._prefix
    });

    dns.lookup(statsd_host, (err, ip) => {
      if (!err) {
        this._client = new lynx(ip, statsd_port, {
          on_error: this.errorHandler
        });
      }

      if (callback) { callback(err); }
    });
  }
}

module.exports = new StatsReporter();
