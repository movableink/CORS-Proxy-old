connect = require 'connect'
request = require 'supertest'
cors = require '../src/cors'

app = connect()
app.use cors()
app.use (req, res) ->
  res.writeHead(200, {'custom': 'foo'})
  res.end('hello')

describe 'cors', ->
  describe "OPTIONS", ->
    it 'sets default headers', (done) ->
      request(app)
        .options('/')
        .expect('access-control-allow-methods', 'HEAD, POST, GET, PUT, PATCH, DELETE')
        .expect(200, done)

    it 'allows standard headers', (done) ->
      request(app)
        .options('/')
        .expect('access-control-allow-headers', /accept-encoding/)
        .expect(200, done)

    it 'allows user-passed headers', (done) ->
      request(app)
        .options('/')
        .set('x-foo', 'bar')
        .expect('access-control-allow-headers', /x-foo/)
        .expect(200, done)

    it 'sends back allow-origin * even if the origin is set', (done) ->
      request(app)
        .options('/')
        .set('origin', 'myorigin')
        .expect('access-control-allow-origin', '*')
        .expect(200, done)

    it 'uses * if the origin is not set', (done) ->
      request(app)
        .options('/')
        .expect('access-control-allow-origin', '*')
        .expect(200, done)

    it 'allows access-control-request-headers override', (done) ->
      request(app)
        .options('/')
        .set('access-control-request-headers', 'foo, bar')
        .expect('access-control-allow-headers', 'foo, bar')
        .expect(200, done)

  describe "GET", ->
    it 'sets default headers', (done) ->
      request(app)
        .get('/')
        .expect('access-control-allow-methods', 'HEAD, POST, GET, PUT, PATCH, DELETE')
        .expect(200, done)

    it 'does not mangle the app headers', (done) ->
      request(app)
        .get('/')
        .expect('custom', 'foo')
        .expect(200, done)
