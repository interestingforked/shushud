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
$ export $(cat sample.env)
$ bundle install
$ bin/db
$ bundle exec bin/provider
$ bundle exec thin start -e production -p $PORT
$ curl -I http://provider_id:provider_token@localhost:$PORT/heartbeat
```
Please see the [API Docs](https://github.com/heroku/shushu/tree/master/doc) for more detailed
usage.

## Running Tests

```bash
$ bin/db test
$ bundle exec turn test/
```
