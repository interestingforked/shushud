# Usage Report

## Purpose

Providers will be submitting billable_events to Shushu. Each billable_event has
a state and a time-stamp. (among other things...) In order to get a more holistic
view of these events, we need to see when one event started and when it was
stopped. If we have a unit that provides a start and stop time, then we can
derive a quantity. With a quantity, we can join in a rate_code and produce a
cost in dollars. The BillableUnit is the object that contains the start/stop,
qty & total. The UsageReport is a collection of BillableUnits wrapped with
meta-data.

## API

### Query Report

```bash
$ curl -X GET https://shushu.heroku.com/accounts/123/usage_reports \
  -d "from=1999-12-01 00:00:00 UTC" \
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
