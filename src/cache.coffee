EventEmitter = require('events').EventEmitter

class Cache extends EventEmitter
  constructor: (@expires) ->
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
    console.log "Request cached for #{expires}ms"
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

  unlock: (key) ->
    value = @get(key)
    delete @locked[key]
    console.log "unlocked with size #{value.body.length}"

    @emit key, value

  setupResponse: (response) ->
    write = response.write.bind(response)

    response.cacheData = ''
    response.write = (data) ->
      response.cacheData += data
      write data

  debugLog: ->
    try
      keys = Object.keys(@cacheBucket)
      size = 0
      size += (@cacheBucket[key].length || 0) for key in keys
      log.debug "Cache has #{keys.length} keys of size #{size}b" if size > 0
    catch e
      log.error "Problem listing cache info"


module.exports = Cache