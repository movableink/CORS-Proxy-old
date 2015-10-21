stats = require('./stats_reporter')

module.exports = ->
  (req, res, next) ->
    start = new Date()

    res.on 'finish', ->
      reqTime = (new Date()) - start
      cacheStatus = res.cacheStatus or 'miss'

      stats.add("requests", "1|c")
      stats.add("cache_#{cacheStatus}", "1|c")
      stats.add(req.method, "1|c")
      stats.add("response_time", "#{reqTime}|ms")

      stats.send()

    next()
