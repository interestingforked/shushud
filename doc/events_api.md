# Billable Events

## Creating Events

This API is idempotent. After the first open or close, subsequent
calls that have identical *event_id*, *state* values will be ignored.

* hid: The id of the resource. (i.e. app_id)
* event_id: An id that is unique to the provider of events. (i.e. psmgr's upid)
* qty: In most cases, this will be 1. However, if a provider wishes to batch events of the same rate_code, the qty field may not be 1.
* time: The UTC time in which the event occured.
* state: Can be 'open' or 'close'.
* rate_code: The slug of the rate code associated with the event. See the rate_code API doc.
* product_name: In the case where the rate code does not define a product_name, each billable_event belonging to that rate_code must specifu a product_name.

### Open Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:event_id \
  -d "qty=1" \
  -d "time=2011-12-01 00:00:00" \
  -d "state=open" \
  -d "rate_code=RT01" \
  -d "product_name=web"
```

### Close Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:event_id \
  -d "time=2011-12-02 00:00:00" \
  -d "state=close"
```

## Querying Events

### Find all events by account_id

```bash
$ curl -X GET \
  https://shushu.heorku.com/accounts/:account_id/billable_events?period_start=2011-11-01&period_end=2011-12-01

HTTP/1.1 200 OK
{
  [
    {
      "event_id": 12345,
      "group": "dyno",
      "name": "web",
      "description": "",
      "qty": 750,
      "rate": 5,
      "from": "2011-11-01 00:00:01 UTC",
      "to": "2011-12-01 00:00:00 UTC",
      "state": "open"
    }
  ]
}
```

