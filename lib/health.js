module.exports = function healthController(req, res, next) {
  if (req.url === '/?health=true') {
    res.writeHead(200, {});
    res.end('ok');
  } else {
    next();
  }
};
