## start the cors proxy

    $ git clone git://github.com/gr2m/CORS-Proxy.git
    $ cd CORS-proxy
    $ npm install .
    $ node server.js

## usage

The cors proxy will start at http://localhost:9292. To access another domain, use the domain name (including port) as the first folder, e.g.

    http://localhost:9292/localhost:3000/sign_in
    http://localhost:9292/my.domain.com/path/to/resource
    etc etc

https sites can be used by appending `:443` to the hostname:

    http://localhost:9292/google.com:443/

cors-proxy caches backend requests by default for 10 seconds.  To modify this, pass cors-proxy the 'X-Reverse-Proxy-TTL' header with a value in seconds:

    var req = new XMLHttpRequest();
    req.open("GET", url, true);
    req.setRequestHeader("X-Reverse-Proxy-TTL", 45); // set cache to 45 seconds
    req.send(null);

cors-proxy will indicate that a cached version was used with the `x-cors-cache` header in the response.

The cache is based on the request method (GET, POST, etc), the URL, and any POST data.  The cache cannot be manually expired, so if you need to bust the cache you can change the URL using a random query param.


