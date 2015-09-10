module.exports = ->
  return (req, res, next) ->
    start = new Date()

    res.on 'finish', ->
      reqTime = (new Date()) - start
      cacheStatus = res.cacheStatus or 'miss'
      console.log "#{new Date().toISOString()} #{res.statusCode} #{req.method} #{req.url} in #{reqTime} ms (cache #{cacheStatus}) #{JSON.stringify(req.headers)}"

    next()
