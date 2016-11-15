const connect = require('connect');
const request = require('supertest');
const cors = require('../lib/cors');
const should = require('should');

let app = connect();
app.use(cors());
app.use(function(req, res) {
  res.writeHead(200, {'custom': 'foo'});
  return res.end('hello');
});

describe('cors', function() {
  describe("OPTIONS", function() {
    it('sets default headers', done =>
      request(app)
        .options('/')
        .expect('access-control-allow-methods', 'HEAD, POST, GET, PUT, PATCH, DELETE')
        .expect(200, done)

    );

    it('allows standard headers', done =>
      request(app)
        .options('/')
        .expect('access-control-allow-headers', /accept-encoding/)
        .expect(200, done)

    );

    it('allows user-passed headers', done =>
      request(app)
        .options('/')
        .set('x-foo', 'bar')
        .expect('access-control-allow-headers', /x-foo/)
        .expect(200, done)

    );

    it('echoes the origin', done =>
      request(app)
        .options('/')
        .set('origin', 'myorigin')
        .expect('access-control-allow-origin', 'myorigin')
        .expect(200, done)

    );

    it('uses * if the origin is not set', done =>
      request(app)
        .options('/')
        .expect('access-control-allow-origin', '*')
        .expect(200, done)

    );

    return it('allows access-control-request-headers override', done =>
      request(app)
        .options('/')
        .set('access-control-request-headers', 'foo, bar')
        .expect('access-control-allow-headers', 'foo, bar')
        .expect(200, done)

    );
  }
  );

  return describe("GET", function() {
    it('sets default headers', done =>
      request(app)
        .get('/')
        .expect('access-control-allow-methods', 'HEAD, POST, GET, PUT, PATCH, DELETE')
        .expect(200, done)

    );

    return it('does not mangle the app headers', done =>
      request(app)
        .get('/')
        .expect('custom', 'foo')
        .expect(200, done)

    );
  }
  );
}
);
