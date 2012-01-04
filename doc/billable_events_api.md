# Billable Events

## Purpose

BillableEvents are the life blood of Shushu. These events will be folded and
combined into an invoice. BillableEvents go into the system and BillableUnits
come out.

## API

### Authentication

You must submit your pvoider id and provider token as username and password for
the API's basic HTTP authentication.

### Creating Events

This API is idempotent with respect to: *provider_id*, *entity_id* & *state*.

* hid: The id of the resource. (i.e. app_id)
* entity_id: An id that is unique to the provider of events. See doc on [entity_ids.](https://github.com/heroku/shushu/tree/master/doc)
* qty: In most cases, this will be 1. However, if a provider wishes to batch events of the same rate_code, the qty field may not be 1.
* time: The UTC time in which the event occured. See doc on [time.](https://github.com/heroku/shushu/tree/master/doc)
* state: Can be 'open' or 'close'.
* rate_code: The slug of the rate code associated with the event. See doc on [rate_codes.](https://github.com/heroku/shushu/blob/master/doc/rate_code_api.md)
* product_name: In the case where the rate code does not define a product_name, each billable_event belonging to that rate_code must specifu a product_name.

#### Open Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:entity_id \
  -d "qty=1" \
  -d "time=2011-12-01 00:00:00" \
  -d "state=open" \
  -d "rate_code=RT01" \
  -d "product_name=web"
```

**Response Code**

* 200 - Event as already been recorded.
* 201 - Event recorded.
* 400 - Missing required arguments.
* 401 - Incorrect Authentication.
* 404 - Rate Code not found.

**Response Body**

```
{"account_id": "123", "hid": "987", "entity_id": "456", "state": "active"}
```


#### Close Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:entity_id \
  -d "time=2011-12-02 00:00:00" \
  -d "state=close"
```

**Response Code**

* 200 - Event as already been recorded.
* 201 - Event recorded.
* 400 - Missing required arguments.
* 401 - Incorrect Authentication.
* 409 - Incorrect timestamp. Closed happened before open.

**Response Body**

```
{"account_id": "123", "hid": "987", "entity_id": "456", "state": "active"}
```

## Issues

There is currently nothing from stopping a provider from submitting an open for
time=2 and a close for time=1. This would result in the computation of a
negative quantity for the corresponding billable_unit.
