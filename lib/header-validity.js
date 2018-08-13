const invalidCharacters = /[^\t\x20-\x7e\x80-\xff]/g;

function hasInvalidCharacters(value) {
  return !!value.match(invalidCharacters);
}

function checkHeaderValidity(req, res, next) {
  if (Object.entries(req.headers).some(([key,value]) => hasInvalidCharacters(value))) {
    res.writeHead(400, {});
    res.end('The header content contains invalid characters');
  } else {
    next();
  }
}

module.exports = {
  hasInvalidCharacters: hasInvalidCharacters,
  checkHeaderValidity: checkHeaderValidity
}
