# Accounts API

Accounts are required to group resources. Each billable_event will have an hid
that references a resource. The AccountOwnershipRecord joins the account and the
billable_event. Hence, the account is merely an object that allows us to create
groups of resources. One side affect of this relationship is that usage reports
are available for accounts. Check out the UsageReportAPI for more details.

This API allows providers the ability to create accounts.

## API

### Create

#### Shushu generated account id

Using the POST endpoint of the API will result in an newly created account with
a Shushu generated id.

```bash
$ curl -X POST https://core:secret@shushu.heroku.com/accounts

{"id": "00001"}
```

#### Shushu generated account id

Using the PUT endpoint of this API allows the provider to control the id and
subsequently makes the API idempotent. The id can be any type of string.

```bash
$ curl -X PUT https://core:secret@shushu.heroku.com/accounts/id@yourdomain.com

{"id": "id@yourdomain.com"}
```

### Delete

Deleting an account is not supported at this time.
