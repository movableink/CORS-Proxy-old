parseUrl = require '../src/parse_url'
describe 'parseUrl', ->
  describe "hostname", ->
    it 'finds the hostname by itself', ->
      path = "/www.google.com"
      parseUrl(path).hostname.should.equal 'www.google.com'

    it 'finds the hostname as part of a path', ->
      path = "/www.google.com/foo/bar"
      parseUrl(path).hostname.should.equal 'www.google.com'

    it 'ignores ports', ->
      path = "/www.google.com:1234/foo"
      parseUrl(path).hostname.should.equal 'www.google.com'

  describe "target", ->
    it 'parses just a domain', ->
      path = "/www.google.com"
      parseUrl(path).target.should.equal 'http://www.google.com/'

    it 'parses a URL with a port', ->
      path = "/www.google.com:1234"
      parseUrl(path).target.should.equal 'http://www.google.com:1234/'

    it 'parses a URL with port 80', ->
      path = "/www.google.com:80"
      parseUrl(path).target.should.equal 'http://www.google.com/'

    it 'parses a URL with SSL', ->
      path = "/www.google.com:443"
      parseUrl(path).target.should.equal 'https://www.google.com/'

    it 'parses a URL with paths', ->
      path = "/www.google.com/foo/bar?baz"
      parseUrl(path).target.should.equal 'http://www.google.com/foo/bar?baz'

  describe "errors", ->
    it 'ignores blank url', ->
      parseUrl('').target.should.equal ''

    it 'ignores null url', ->
      parseUrl(null).target.should.equal ''