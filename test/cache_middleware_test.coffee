connect = require 'connect'
request = require 'supertest'
Cache   = require '../src/cache'

cache = new Cache(10000, logging: false)

app = connect()
app.use cache.middleware()
app.use (req, res) ->
  res.writeHead(200, {'custom': 'foo'})
  res.end('hello')

beforeEach ->
  cache.clear()

describe 'cacheMiddleware', ->
  describe 'cold cache', ->
    it 'returns a cache miss', (done) ->
      request(app)
        .get('/')
        .expect('x-cors-cache', 'miss')
        .expect("hello")
        .expect 200, done

    it 'sets the cache', (done) ->
      request(app)
        .get('/')
        .expect 200, ->
          cache.get('GET,/').body.should.equal "hello"
          done()

    it 'unlocks the cache', (done) ->
      request(app)
        .get('/')
        .expect 200, ->
          cache.inFlight('GET,/').should.equal false
          done()

  describe 'cache wait', ->
    it 'returns a cache wait', (done) ->
      cache.lock "GET,/"

      request(app)
        .get('/')
        .expect('x-cors-cache', 'wait')
        .expect('x-foo', 'bar')
        .expect('foobar')
        .expect 200, done

      setTimeout ->
        cache.set "GET,/",
          headers: {'x-foo': 'bar'}
          body: "foobar"
          statusCode: 200
        cache.unlock "GET,/"
      , 5

  describe 'cache hit', ->
    it 'returns a cache hit', (done) ->
      cache.set "GET,/",
        headers: {'x-foo': 'bar'}
        body: "foobar"
        statusCode: 200

      request(app)
        .get('/')
        .expect('x-cors-cache', 'hit')
        .expect('x-foo', 'bar')
        .expect('foobar')
        .expect 200, done
