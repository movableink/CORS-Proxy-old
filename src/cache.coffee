EventEmitter = require('events').EventEmitter

class Cache extends EventEmitter
  constructor: (@expires) ->
    @cacheBucket = {}
    @locked = {}

    setInterval =>
      @debugLog()
    , 60 * 1000

  get: (key) ->
    @cacheBucket[key]

  has: (key) ->
    @cacheBucket[key]?

  set: (key, value) ->
    @cacheBucket[key] = value
    setTimeout (=> delete @cacheBucket[key]), @expires

  # is there currently another request running on this key?
  inFlight: (key) ->
    @locked[key]?

  # wait for another request to finish, and retrieve its value
  getLater: (key, cb) ->
    @once key, (value) ->
      cb(value)

  lock: (key) ->
    @locked[key] = true

  unlock: (key, value) ->
    delete @locked[key]

    @emit key, value

  debugLog: ->
    try
      keys = Object.keys(@cacheBucket)
      size = 0
      size += (@cacheBucket[key].length || 0) for key in keys
      log.debug "Cache has #{keys.length} keys of size #{size}b" if size > 0
    catch e
      log.error "Problem listing cache info"


module.exports = Cache