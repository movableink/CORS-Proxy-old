module.exports = ->
  return (req, res, next) ->
    start = new Date()

    res.on 'finish', ->
      reqTime = (new Date()) - start
      cacheStatus = res.cacheStatus or 'miss'
      console.log JSON.stringify(
        date: new Date().toISOString()
        statusCode: res.statusCode
        method: req.method
        url: req.url
        time: reqTime
        cacheStatus: cacheStatus
        headers: req.headers
      )

    res.on 'close', ->
      reqTime = (new Date()) - start
      cacheStatus = res.cacheStatus or 'miss'
      console.log JSON.stringify(
        date: new Date().toISOString()
        statusCode: res.statusCode
        method: req.method
        url: req.url
        time: reqTime
        cacheStatus: cacheStatus
        headers: req.headers
      )

    next()
