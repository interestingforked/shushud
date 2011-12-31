# Accounts API

## Purpose

Accounts are required to group resources. Each billable_event will have an hid
that references a resource. The AccountOwnershipRecord joins the account and the
billable_event. Hence, the account is merely an object that allows us to create
groups of resources. One side affect of this relationship is that usage reports
are available for accounts. Check out the UsageReportAPI for more details.

This API allows trusted_consumers the ability to create accounts.

## API

### Create

```bash
$ curl -X POST https://core:secret@shushu.heroku.com/accounts

{"id": "00001"}
```

### Delete

Deleting an account is not supported at this time.
