# Cache is a simple in-memory cache.
#
# It supports expiration (using setTimeout) and locking.

EventEmitter = require('events').EventEmitter
cacheMiddleware = require './cache_middleware'

class Cache extends EventEmitter
  constructor: (@expires, @options={}) ->
    @cacheBucket = {}
    @locked = {}
    @setMaxListeners(5000)

    setInterval =>
      @debugLog()
    , 60 * 1000

  get: (key) ->
    @cacheBucket[key]

  has: (key) ->
    @cacheBucket[key]?

  set: (key, value, expires) ->
    @cacheBucket[key] = value
    expires or= @expires
    setTimeout (=> delete @cacheBucket[key]), expires

  # is there currently another request running on this key?
  inFlight: (key) ->
    @locked[key]?

  # wait for another request to finish, and retrieve its value
  getLater: (key, cb) ->
    @once key, (value) ->
      cb(value)

  lock: (key) ->
    @locked[key] = true

  # other requests were waiting on our response, give it to them
  unlock: (key, defaultValue) ->
    value = @get(key) or defaultValue
    delete @locked[key]

    @emit key, value

  # other requests were waiting on our response, but we didn't deliver
  abandon: (key) ->
    @unlock(key, null)

  clear: ->
    @cacheBucket = {}
    @locked = {}

  keys: ->
    Object.keys(@cacheBucket)

  log: (message) ->
    console.log JSON.stringify(
      CACHE: message
    ) unless @options.logging is false

  debugLog: ->
    try
      keys = Object.keys(@cacheBucket)
      size = 0
      size += (@cacheBucket[key].length || 0) for key in keys
      @log "Info: has #{keys.length} keys of size #{size}b" if size > 0
    catch e
      @log "Problem listing cache info"

  middleware: ->
    cacheMiddleware @

module.exports = Cache
