const parseUrl = require('../lib/parse-url');
const should = require('should');

describe('parseUrl', function() {
  describe("hostname", function() {
    it('finds the hostname by itself', function() {
      let path = "/www.google.com";
      return parseUrl(path).hostname.should.equal('www.google.com');
    }
    );

    it('finds the hostname as part of a path', function() {
      let path = "/www.google.com/foo/bar";
      return parseUrl(path).hostname.should.equal('www.google.com');
    }
    );

    return it('ignores ports', function() {
      let path = "/www.google.com:1234/foo";
      return parseUrl(path).hostname.should.equal('www.google.com');
    }
    );
  }
  );

  describe("target", function() {
    it('parses just a domain', function() {
      let path = "/www.google.com";
      return parseUrl(path).target.should.equal('http://www.google.com/');
    }
    );

    it('parses a URL with a port', function() {
      let path = "/www.google.com:1234";
      return parseUrl(path).target.should.equal('http://www.google.com:1234/');
    }
    );

    it('parses a URL with port 80', function() {
      let path = "/www.google.com:80";
      return parseUrl(path).target.should.equal('http://www.google.com/');
    }
    );

    it('parses a URL with SSL', function() {
      let path = "/www.google.com:443";
      return parseUrl(path).target.should.equal('https://www.google.com/');
    }
    );

    return it('parses a URL with paths', function() {
      let path = "/www.google.com/foo/bar?baz";
      return parseUrl(path).target.should.equal('http://www.google.com/foo/bar?baz');
    }
    );
  }
  );

  return describe("errors", function() {
    it('ignores blank url', () => parseUrl('').target.should.equal('')
    );

    return it('ignores null url', () => parseUrl(null).target.should.equal('')
    );
  }
  );
}
);
