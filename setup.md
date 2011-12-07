# Setup

Shushu is a heroku application. Components include:

* Thin web server
* Postgresql Database

## Running Locally

```bash
$ export DATABASE_URL='postgres://username:password@localhost/shushu'
$ export RACK_ENV='production'
$ bundle install
$ bundle exec bin/reset
$ bundle exec bin/console
irb: Provider.create(:name => "shushutest", :token => "pass")
$ foreman start web
$ curl -I http://1:pass@localhost:$PORT/resources/heartbeat
HTTP/1.1 200 OK
Content-Type: text/html;charset=utf-8
Content-Length: 11
Connection: keep-alive
Server: thin 1.2.11 codename Bat-Shit Crazy
```

## POST a rate code

```bash
$ curl -X POST http://1:pass@localhost:$PORT/rate_codes/ \
  -d "rate=5" \
  -d "description=myratecode" \
  -d "slug=RT01"
```

## PUT an event

```bash
$ curl -X PUT http://1:pass@localhost:$PORT/resources/app123/billable_events/1 \
  -d "from=2011-01-01 00:00:00" \
  -d "qty=1" \
  -d "rate_code=RT01"

```

## Running Tests

```bash
$ bundle
$ bundle exec bin/reset test
$ bundle exec turn test/
```
