module.exports = ->
  return (req, res, next) ->
    start = new Date()

    res.on 'finish', ->
      finish = new Date()
      reqTime = finish - start
      cacheStatus = res.cacheStatus or 'miss'

      console.log JSON.stringify(
        date: finish.toISOString()
        statusCode: res.statusCode
        method: req.method
        url: req.url
        time: reqTime
        cacheStatus: cacheStatus
        headers: req.headers
      )

    res.on 'close', ->
      finish = new Date()
      reqTime = finish - start
      cacheStatus = res.cacheStatus or 'miss'

      console.log JSON.stringify(
        date: finish.toISOString()
        statusCode: res.statusCode
        method: req.method
        url: req.url
        time: reqTime
        cacheStatus: cacheStatus
        headers: req.headers
      )

    next()
