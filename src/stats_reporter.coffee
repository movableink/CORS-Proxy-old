lynx = require('lynx')
dns  = require('dns')
os   = require("os")

class StatsReporter
  constructor: ->
    @clear()

  clear: ->
    @_stats = {}

  client: ->
    @_client

  stats: ->
    @_stats

  add: (key, value) ->
    @_stats[key] = value

  errorHandler: (err) ->
    console.error('error reporting to statsd:', err)

  send: ->
    return unless @_client

    fullStats = {}
    for stat, value of @_stats
      fullStats["#{@_prefix}.#{stat}"] = value

    @_client.send fullStats
    @clear()

  setup: (callback) ->
    hostname = os.hostname().split('.')[0]

    statsd_host = process.env.STATSD_HOST || "localhost"
    statsd_port = process.env.STATSD_PORT || 8125
    @_prefix = process.env.STATSD_PREFIX || "cors.#{hostname}"

    console.log("Reporting stats to #{statsd_host}:#{statsd_port} with prefix #{@_prefix}")

    dns.lookup statsd_host, (err, ip) =>
      unless err
        @_client = new lynx(ip, statsd_port, {on_error: @errorHandler})

      callback err if callback

statsReporter = new StatsReporter()

module.exports = statsReporter
