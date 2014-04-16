# parseUrl parses URLs out of paths
#
# Example:
#
#   path = "/movableink.com:443/product"
#   parseUrl(path)
#   =>
#   {
#     hostname: 'movableink.com',
#     path: '/product',
#     target: 'https://movableink.com/product'
#   }

url = require 'url'

module.exports = (requestUrl) ->
  [_, port] = (requestUrl.match(/^\/[^\/]+\:(\d+)/) || [])
  port = parseInt(port, 10) or 80
  proto = if port is 443 then 'https' else 'http'
  target = url.parse(requestUrl.replace(/^\//, "#{proto}://"))
  target.host = null
  target.port = null if port is 80 or port is 443

  proxyUrl =
    hostname: target.hostname
    path: target.path
    target: target.format()
