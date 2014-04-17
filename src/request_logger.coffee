module.exports = ->
  return (req, res, next) ->
    start = new Date()

    res.on 'finish', ->
      reqTime = (new Date()) - start
      cacheStatus = res.cacheStatus or 'miss'
      console.log "#{res.statusCode} GET #{req.url} in #{reqTime} ms (cache #{cacheStatus})"

    next()