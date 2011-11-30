# Setup

Shushu is a heroku application. Components include:

* Thin web server
* Postgresql Database

## Running Locally

```bash
$ createdb shushu
$ export DATABASE_URL='postgres://username:password@localhost/shushu'
$ export RACK_ENV='production'
$ bundle
$ bundle exec sequel -m migrations/ $DATABASE_URL
$ bundle exec bin/console
irb: Provider.create(:name => "shushutest", :token => "pass")
$ foreman start web
$ curl -I http://1:pass@localhost:3000/heartbeat
HTTP/1.1 200 OK
Content-Type: text/html;charset=utf-8
Content-Length: 11
Connection: keep-alive
Server: thin 1.2.11 codename Bat-Shit Crazy
```
## PUTing an event

```bash
$ curl -X PUT http://1:pass@localhost:$PORT/resources/app123/billable_events/1 \
  -d "reality_from=2011-01-01 00:00:00" \
  -d "qty=1" \
  -d "rate_code=SG001"

```

## Running Tests

```bash
$ gem install turn
$ turn test/
```
