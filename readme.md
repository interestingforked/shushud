# 収集

## Name

Shushu is japanese for collector. Shushu collects and maintains all data related
to usage & billing.

## Purpose

* Track and store billable_events in an append-only log.
* Track and store resource ownerships.
* Manage rate codes for billable events.

## Setup

```bash
$ export $(cat sample.env)
$ bundle install
$ bin/db-reset
$ bin/web
$ curl -i -X HEAD https://localhost:$PORT/
```

## Running Tests

```bash
$ export $(cat sample.env)
$ bundle install
$ bin/db-reset test
$ bundle exec turn/test
```
