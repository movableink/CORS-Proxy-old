const headerValidity = require('../lib/header-validity');
const should         = require('should');

describe('headerValidity', function() {
  describe('hasInvalidCharacters', function() {
    it('should return true when invalid characters are present', function() {
      headerValidity.hasInvalidCharacters('ƒoo').should.be.exactly(true);
    });

    it('should return false when no invalid characters are present', function () {
      headerValidity.hasInvalidCharacters('foo').should.be.exactly(false);
    });
  });
});
