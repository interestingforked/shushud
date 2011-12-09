# Resource Ownership API

## Purpose

Providers will be submitting billable events that are related to a resource in
the cloud. (A resource will primaraly be a heroku app but we should not limit
ourselves to an app, hence we use resource as the noun.) When we build an
invoice for an account, we will need to determine which billable events will
be associated with the invoice. We will also need to take into consideration
that one resource may have many owners within a period. We should only invoice
the owners for the period of time that they owned the resource.

## API

### Authentication

Each consumer will have a secret token. Basic HTTP will be used to validate the
token.

### POST Activate

```bash
$ curl -i -X POST http://shushu.heroku.com/resource_ownership \
  -d "hid=987" \
  -d "account_id=123"

```

### PUT Transfer

```bash
$ curl -i -X PUT http://shushu.heroku.com/resource_ownership \
  -d "hid=987" \
  -d "prev_account_id=123" \
  -d "account_id=456"
```

### DELETE Deactivate

```bash
$ curl -i -X DELETE http://shushu.heroku.com/resource_ownership \
  -d "hid=987" \
  -d "account_id=456"
```


