# Resource Ownership Events API

## Purpose

In order to associate accounts with resources, providers (e.g. Core) will need
to send events to shushu when resources are created, activated and moved between
accounts. Assuming Shushu has billable_events, accounts & resource ownership
events, usage reports can be generated for accounts.

## API

This API is idempotent. Furthermore, it does not care about the order in which
it receives events. For instance, you can send the inactive state prior to
sending the active state. In such a case, shushu will neglect all related
records for reporting until the active record arrives.

It is recomended to follow the [event buffering](https://github.com/heroku/engineering-docs/blob/master/event-buffering.md)
approach when implementing a client for this library.

### Activate

If no account can be found using the :account_id, Shushu will create one
during the resource_ownership request.

```bash
$ curl -i -X PUT https://shushu.heroku.com/accounts/:account_id/resource_ownerships/:entity_id \
  -d "state=active"                 \
  -d "resource_id=987"              \
  -d "time=1999-12-31 00:00:00 UTC"

{"account_id": "123", "resource_id": "987", "entity_id": "456", "state": "active"}
```
### Deactivate

```bash
$ curl -i -X PUT https://shushu.heroku.com/accounts/:account_id/resource_ownerships/:entity_id \
  -d "resource_id=789"              \
  -d "state=inactive"               \
  -d "time=1999-12-31 00:00:00 UTC"

{"account_id": "123", "resource_id": "789", "entity_id": "456", "state": "inactive"}
```

### Query

```bash
$ curl -X GET https://shushu.heroku.com/accounts/:account_id/resource_ownerships
```
