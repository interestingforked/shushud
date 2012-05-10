# Setup

Shushu is a heroku application. Components include:

* Thin
* PostgreSQL
* Cron (heroku scheduler)

## Running Locally

```bash
$ export $(cat sample.env)
$ bundle install
$ bin/db
$ bundle exec bin/provider
$ bundle exec thin start -e production -p $PORT
$ curl -I http://provider_id:provider_token@localhost:$PORT/heartbeat
```
Please see the [API Docs](https://github.com/heroku/shushu/tree/master/doc) for more detailed
usage.

## Deploying to Heroku

```bash
$ heroku create -s cedar
$ heroku addons:add heroku-postgresql:ika #ika not needed although it is the best
$ heroku pg:promote DB_COLOR
$ heroku run bundle exec bin/migrate
$ cat sample.env | xargs -t -I % heroku config:add %
```

## Running Tests

```bash
$ bin/db test
$ bundle exec turn test/
```
