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

### Open Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:event_id \
  -d "qty=1" \
  -d "time=2011-12-01 00:00:00" \
  -d "state=open" \
  -d "rate_code=RT01"
```

### Close Event

```bash
$ curl -X PUT http://shushu.heroku.com/resources/:hid/billable_events/:event_id \
  -d "time=2011-12-02 00:00:00" \
  -d "state=close"
```

## Querying Events
