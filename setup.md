# Setup

Shushu is a heroku application. Components include:

* Thin web server
* Postgresql Database

## Running Locally

```bash
$ bundle
$ foreman start
$ curl -I http://localhost:3000/heartbeat
HTTP/1.1 200 OK
Content-Type: text/html;charset=utf-8
Content-Length: 11
Connection: keep-alive
Server: thin 1.2.11 codename Bat-Shit Crazy
```

## Running Tests

```bash
$ gem install turn
$ turn test/
```
