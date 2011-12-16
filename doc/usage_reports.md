# Usage Report

## The Problem:

Each account will own resources over periods of time. This ownership implies that
there are billable_events associated with the account. We need some way to
communicate the usage that is incurred by the account for an arbitrary period of
time. The account should also be able to view historical usage. This usage
should not be a simple collection of billable events as the data will not
be easily computable for cost. We need to produce a collection of billable
units.


## A Solution:

A usage report will be a collection of billable_events that have been folded
into billable units. The report will generated from an account_id and a from and
to time-stamp. It will not be persisted but computed as the sum of a series of
billable_events. When an invoice is generated, we could persist the usage report
to a snapshot service if we wanted to isolate reports from changes in the
reporting process. A usage report will also have a total dollar amount.

## API

### Query Report

```bash
$ curl -X GET https://shushu.heroku.com/accounts/123/usage_reports \
  -d "from=1999-12-01 00:00:00 UTC"
  -d "to=2000-01-01 00:00:00 UTC"
```

**Response:**

```
{
  "account_id": "123",
  "total": "7400",
  "from": "1999-12-01 00:00:00 UTC",
  "to": "2000-01-01 00:00:00 UTC",
  "billable_units": [
    {
      "product_group": "dyno",
      "product_name": "web",
      "qty": "744",
      "rate": "5",
      "total": "3700",
    },
    {
      "product_group": "dyno",
      "product_name": "worker",
      "qty": "744",
      "rate": "5",
      "total": "3700",
    }
  ]
}
```
