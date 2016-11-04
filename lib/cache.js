// Cache is a simple in-memory cache.
//
// It supports expiration (using setTimeout) and locking.

const EventEmitter = require('events').EventEmitter;
const cacheMiddleware = require('./cache-middleware');

const log = require('./log');

class Cache extends EventEmitter {
  constructor(expires, options) {
    super();

    this.expires = expires;
    this.options = options || {};
    this.cacheBucket = {};
    this.locked = {};
    this.setMaxListeners(5000);

    setInterval(() => {
      this.debugLog();
    }, 60 * 1000);
  }

  get(key) {
    return this.cacheBucket[key];
  }

  has(key) {
    return (this.cacheBucket[key] != null);
  }

  set(key, value, expires) {
    this.cacheBucket[key] = value;
    expires = expires || this.expires;
    setTimeout((() => delete this.cacheBucket[key]), expires);
  }

  // is there currently another request running on this key?
  inFlight(key) {
    return this.locked[key] != null;
  }

  // wait for another request to finish, and retrieve its value
  getLater(key, cb) {
    this.once(key, value => cb(value));
  }

  lock(key) {
    this.locked[key] = true;
  }

  // other requests were waiting on our response, give it to them
  unlock(key, defaultValue) {
    let value = this.get(key) || defaultValue;
    delete this.locked[key];

    this.emit(key, value);
  }

  // other requests were waiting on our response, but we didn't deliver
  abandon(key) {
    this.unlock(key, null);
  }

  clear() {
    this.cacheBucket = {};
    this.locked = {};
  }

  keys() {
    return Object.keys(this.cacheBucket);
  }

  logMessage(message) {
    if (this.options.logging !== false) {
      log({
        CACHE: message
      });
    }
  }

  debugLog() {
    try {
      let keys = Object.keys(this.cacheBucket);
      let size = 0;

      keys.forEach((key) => {
        size += (this.cacheBucket[key].length || 0);
      });

      if (size > 0) {
        this.logMessage(`Info: has ${keys.length} keys of size ${size}b`);
      }
    } catch (e) {
      this.logMessage("Problem listing cache info");
    }
  }

  middleware() {
    return cacheMiddleware(this);
  }
}

module.exports = Cache;
