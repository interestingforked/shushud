# Reporting

The general pattern for report generation is to create the report mechanics
as a PostgreSQL function. Once the function is created, a thin wrapper is added
to the report_service ruby module. Here are the default reports provided by Shushu:

* Invoice
* Usage Report
* Rate Code Report

## Invoice

The invoice is the staple report of Shushu. Invoices are meant to be generated
and turned into [receivables]. Invoices depend on [payment_methods], [accounts],
[account_ownerships], [resource_ownerships], and [billable_events]. Invoices
also take into account [qty credits]. For instance, dyno-hour credits will be
applied to an invoice with respect to the billable events belonging to the
invoices that have product_name=dyno.

## Usage Report

### Purpose

Providers will be submitting billable_events to Shushu. Each billable_event has
a state and a time-stamp. (among other things...) In order to get a more holistic
view of these events, we need to see when one event started and when it was
stopped. If we have a unit that provides a start and stop time, then we can
derive a quantity. With a quantity, we can join in a rate_code and produce a
cost in dollars. The BillableUnit is the object that contains the start/stop,
qty & total. The UsageReport is a collection of BillableUnits wrapped with
meta-data.

### API

#### Query Report

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

## Rate Code Report

Strategy:

Case 1 - Provider Payment Reports

add-ons will query their DB for a list of all rate codes that need to
be included in the report. For each rate code it will hit the Shushu
API to retreive the billable_units. Once the data has been collected,
add-ons will group the units by resource_id and compute the total for each
respective resource.

Case 2 - Dashboard

Use the same strategy in case 1. execpt add-ons only cares about the total in
the report doc, not all of the supporting billable units.

```bash
$ curl -x GET https://provider:token@shushu.heroku.com/rate_codes/:rate_code_slug/billable_units?start=time&end=time

{
  "rate_code": :rate_code_slug,
  "total": 10000,
  "billable_units": [
    {
      "resource_id": "app123",
      "start": time,
      "end": time,
      "qty": 0.007,
      "rate": 100,
      "product_group": "addon",
      "product_name": "mongohq",
      "product_description": "desc"
    }
  ]
}
```
