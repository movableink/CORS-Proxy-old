getRawBody = require 'raw-body'

module.exports = ->
  return (req, res, next) ->
    getRawBody req,
      length: req.headers['content-length']
      limit: '100kb'
      encoding: 'utf8'
    , (err, string) ->
      req.body = if err then '' else string
      next()
