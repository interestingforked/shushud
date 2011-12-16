# Resource Ownership API

## Purpose

Providers will be submitting billable events that are related to a resource in
the cloud. (A resource will primarily be a heroku app but we should not limit
ourselves to an app, hence we use resource as the noun.) When we build an
invoice for an account, we will need to determine which billable events will
be associated with the invoice. We will also need to take into consideration
that one resource may have many owners within a period. We should only invoice
the owners for the period of time that they owned the resource.

## API

### Authentication

Each consumer will have a secret token. Basic HTTP will be used to validate the
token.

### Event ID

The problem with receiving events that involve activation and deactivation is that it is difficult to determine which active event to deactivate upon
receiving a deactivation call. Consider an hid and two accounts. Say that this
hid bounces back and forth between accounts. Also suppose that one of the
deactivation calls was delayed by the client. This implies that our API will be
receiving call in no particular order. Also given that there will be many
records that match account_id and hid and even state (when calls are delayed) we
need a systematic way to track which call belongs to which
resource_ownership_record. Hence, event_id.

Event_ids group events together. To deactivate a resource_ownership_record, one
must provide the event_id that was used to activate the record. Transfers will
support the prev_event_id and the new_account_id as well.

### Activate

```bash
$ curl -i -X POST https://shushu.heroku.com/accounts/:account_id/resource_ownerships/:event_id \
  -d "hid=987"
  -d "time=1999-12-31 00:00:00 UTC"
```

**Responses**

* 201 - Resource ownership record was created.
* 404 - Account not found.
* 409 - There is already an activation resource_ownership_record with the submitted event_id.

```
{"account_id": "123", "hid": "987", "event_id": "456", "state": "active"}
```

### Transfer

```bash
$ curl -i -X PUT https://shushu.heroku.com/accounts/:prev_account_id/resource_ownerships/:prev_event_id \
  -d "hid=987" \
  -d "account_id=123" \
  -d "event_id=456" \
  -d "time=1999-12-31 00:00:00 UTC"
```
**Responses**

* 200 - Resource ownership record was transfered.
* 404 - Account not found.
* 409 - There is already an activation resource_ownership_record with the submitted event_id.

```
{"account_id": "456", "hid": "987", "event_id": "789", "state": "active"}
```

### Deactivate

```bash
$ curl -i -X DELETE https://shushu.heroku.com/accounts/:account_id/resource_ownerships/:event_id \
  -d "hid=789" \
  -d "time=1999-12-31 00:00:00 UTC"
```

### Query

The motivation behind this endpoint is to provide a debugging interface.

```bash
$ curl -X GET https://shushu.heroku.com/accounts/:account_id/resource_ownerships
```

### Issues

It is not clear what would happen if a transfer call was issued with the
identical account_ids. Likewise for transferes with identical event_ids.
