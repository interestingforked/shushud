# Billable Events API

## Purpose

A billable event represents an event for which the provider of the event would
like to bill a customer for. For example, the process manager will provide
billable events for Heroku customers who start and stop processes. Along with
the state of the events (open or close) the provider must provide a resource id
and a rate code id so that Shushu can associate the event with a product and
eventually a customer.

## API

This API is idempotent with respect to the provider_id, entity_id, and the
state. This API also neglects the order in which events with the same entity_id
and different state are received. For example, you can send the close event
for an entity before sending the open event. In this case, Shushu will ignore
the event for any reporting calculations until the open event is received.

It is recomended to follow the [event buffering](https://github.com/heroku/engineering-docs/blob/master/event-buffering.md)
approach when implementing a client for this library.

### Create Open Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:entity_id \
  -d "qty=1"                    \
  -d "time=2011-12-01 00:00:00" \
  -d "state=open"               \
  -d "rate_code=RT01"           \
  -d "product_name=web"         \
  -d "description=bin/web"      \

{"account_id": "123", "hid": "987", "entity_id": "456", "state": "active"}
```

**Response Code**

* 200 - Event as already been recorded.
* 201 - Event recorded.
* 400 - Missing required arguments.
* 404 - Rate Code not found.


### Create Close Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:entity_id \
  -d "time=2011-12-02 00:00:00" \
  -d "state=close"

{"account_id": "123", "hid": "987", "entity_id": "456", "state": "active"}
```

**Response Code**

* 200 - Event as already been recorded.
* 201 - Event recorded.
* 400 - Missing required arguments.

## Issues

There is currently nothing from stopping a provider from submitting an open for
time=2 and a close for time=1. This would result in the computation of a
negative quantity for the corresponding billable_unit.
