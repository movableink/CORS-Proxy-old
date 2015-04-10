module.exports = (req, res) ->
  if req.url == '/?health=true'
    res.writeHead(200, {})
    res.end('ok')
