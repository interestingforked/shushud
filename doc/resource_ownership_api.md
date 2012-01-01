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
