const connect = require('connect');
const request = require('supertest');
const Cache = require('../lib/cache');
const bodyParser = require('body-parser');
const should = require('should');

let cache = new Cache(10000, {logging: false});

let makeApp = function(cb) {
  let app = connect();
  app.use(bodyParser.raw({ type: (req) => { return req.method === 'POST'; } }));
  app.use(cache.middleware());
  app.use(cb);
  return app;
};

let app = makeApp(function(req, res) {
  res.writeHead(200, {'custom': 'foo'});
  return res.end('hello');
});

let slowApp = makeApp((req, res) =>
  setTimeout(function() {
    res.writeHead(200, {'custom': 'custom', 'foo': 'foo'});
    return res.end('hello');
  }
  , 200)
);

let brokenApp = makeApp((req, res) =>
  setTimeout(function() {
    res.writeHead(500, {'custom': 'custom', 'foo': 'foo'});
    return res.end('b0rked');
  }
  , 200)
);

beforeEach(() => cache.clear());

describe('cacheMiddleware', function() {
  describe('cold cache', function() {
    it('returns a cache miss', done =>
      request(app)
        .get('/')
        .expect('x-cors-cache', 'miss')
        .expect("hello")
        .expect(200, done)

    );

    it('sets the cache', done =>
      request(app)
        .get('/')
        .set('origin', 'http://foobar.com')
        .expect(200, function() {
          cache.get("GET,/,http://foobar.com").body.should.equal("hello");
          return done();
        }
      )

    );

    it('uses * origin if no origin sent', done =>
      request(app)
        .get('/')
        .expect(200, function() {
          cache.get("GET,/,*").body.should.equal("hello");
          return done();
        }
      )

    );

    return it('unlocks the cache', done =>
      request(app)
        .get('/')
        .expect(200, function() {
          cache.inFlight("GET,/,*").should.equal(false);
          return done();
        }
      )

    );
  }
  );

  describe('POST', () =>
    it('sets the cache', function(done) {
      let body = '{"foo": "bar"}';
      let hash = '94232c5b8fc9272f6f73a1e36eb68fcf'; // md5 hash of {"foo": "bar"}

      return request(app)
        .post('/')
        .send(body)
        .expect(200, function() {
          let response = cache.get(`POST,/,*,${hash}`);
          response.body.should.equal("hello");
          return done();
        }
      );
    }
    )

  );

  describe('cache wait', () =>
    it('returns a cache wait', function(done) {
      cache.lock("GET,/,*");

      request(app)
        .get('/')
        .expect('x-cors-cache', 'wait')
        .expect('x-foo', 'bar')
        .expect('foobar')
        .expect(200, done);

      return setTimeout(function() {
        cache.set("GET,/,*", {
          headers: {'x-foo': 'bar', 'x-cors-cache': 'miss'},
          body: "foobar",
          statusCode: 200
        }
        );
        return cache.unlock("GET,/,*");
      }
      , 5);
    }
    )

  );

  describe('cache hit', () =>
    it('returns a cache hit', function(done) {
      cache.set("GET,/,*", {
        headers: {'x-foo': 'bar', 'x-cors-cache': 'miss'},
        body: "foobar",
        statusCode: 200
      }
      );

      return request(app)
        .get('/')
        .expect('x-cors-cache', 'hit')
        .expect('x-foo', 'bar')
        .expect('foobar')
        .expect(200, done);
    }
    )

  );

  describe('thundering herd', () =>
    it('handles multiple requests properly', function(done) {
      request(slowApp)
        .get('/')
        .set('X-Reverse-Proxy-TTL', "1")
        .expect('x-cors-cache', 'miss')
        .expect('hello')
        .expect(200);

      return request(slowApp)
        .get('/')
        .set('X-Reverse-Proxy-TTL', "1")
        .expect('x-cors-cache', 'wait')
        .expect('hello')
        .expect(200)
        .end(() =>
          request(slowApp)
            .get('/')
            .set('X-Reverse-Proxy-TTL', "1")
            .expect('x-cors-cache', 'hit')
            .expect('hello')
            .expect(200)
            .end(() =>
              setTimeout(() =>
                request(slowApp)
                  .get('/')
                  .expect('x-cors-cache', 'miss')
                  .expect('hello')
                  .expect(200)
                  .end(done)

              , 1200)
          )
      );
    }
    )

  );

  return describe('thundering herd w/bad response', () =>
    it('handles multiple requests gracefully', function(done) {
      request(brokenApp)
        .get('/')
        .set('x-reverse-proxy-ttl', "1")
        .expect('x-cors-cache', 'miss')
        .expect('b0rked')
        .expect(500);

      return request(brokenApp)
        .get('/')
        .set('x-reverse-proxy-ttl', "1")
        .expect('x-cors-cache', 'wait')
        .expect('b0rked')
        .expect(500)
        .end(() =>
          request(brokenApp)
            .get('/')
            .set('x-reverse-proxy-ttl', "1")
            .expect('x-cors-cache', 'hit')
            .expect('b0rked')
            .expect(500)
            .end(() =>
              setTimeout(() =>
                request(brokenApp)
                  .get('/')
                  .set('x-reverse-proxy-ttl', "1")
                  .expect('x-cors-cache', 'miss')
                  .expect('b0rked')
                  .expect(500)
                  .end(done)

              , 300)
          )
      );
    }
    )

  );
}
);
