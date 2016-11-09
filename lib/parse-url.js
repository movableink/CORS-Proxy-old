'use strict';

// parseUrl parses URLs out of paths
//
// Example:
//
//   path = "/movableink.com:443/product"
//   parseUrl(path)
//   =>
//   {
//     hostname: 'movableink.com',
//     path: '/product',
//     target: 'https://movableink.com/product'
//   }

const url = require('url');

module.exports = function parseUrl(requestUrl) {
  if (!requestUrl) { return { target: '', hostname: '' }; }

  let pair = (requestUrl.match(/^\/[^\/]+\:(\d+)/) || []);
  let port = pair[1];
  port = parseInt(port, 10) || 80;

  const proto = port === 443 ? 'https' : 'http';
  let target = url.parse(requestUrl.replace(/^\//, `${proto}://`));
  target.host = null;
  if (port === 80 || port === 443) { target.port = null; }

  return {
    hostname: target.hostname,
    path: target.path,
    target: target.format(),
    isHttps: (proto === 'https')
  };
};
