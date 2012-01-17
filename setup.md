# Setup

Shushu is a heroku application. Components include:

* Thin
* PostgreSQL
* Memcahed
* Beanstalkd
* Cron (heroku scheduler)

## Running Locally

```bash
$ memcached&; beanstalkd&
$ export DATABASE_URL='postgres://username:password@localhost/shushu'
$ export RACK_ENV='production'
$ export PORT=8000
$ bundle install
$ bin/db
$ bundle exec bin/console
irb: p=Provider.create; p.reset_token!("secret")
$ bundle exec thin start -e production -p $PORT
$ curl -I http://1:secret@localhost:$PORT/heartbeat
HTTP/1.1 200 OK
```
Please see the [API Docs](https://github.com/heroku/shushu/tree/master/doc) for more detailed
usage.

## Running Tests

```bash
$ bundle
$ bundle exec bin/db test
$ bundle exec turn test/
```
