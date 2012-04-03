# Reporting

The general pattern for report generation is to create the report mechanics
as a PostgreSQL function. Once the function is created, a thin wrapper is added
to the report_service ruby module. Here are the default reports provided by Shushu:

* Invoice
* Usage Report
* Rate Code Report
* Resource Difference
* Revenue Report

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
$ curl -X GET https://provider:token@shushu.heroku.com/rate_codes/:rate_code_slug/billable_units?from=time&to=time

{
  "rate_code": :rate_code_slug,
  "total": 10000,
  "billable_units": [
    {
      "resource_id": "app123",
      "from": time,
      "to": time,
      "qty": 0.007,
      "rate": 100,
      "product_group": "addon",
      "product_name": "mongohq",
      "product_description": "desc"
    }
  ]
}
```

## Resource Difference

Over time, resources will accumulate billable_events in such a way that
they increase and decrease their spend with respect to a billing period. For
example, if I have an app that uses 1 dyno for the month of January and uses
2 dynos for the month of February, I have a difference of 1 dyno between January
and February. This report will return a list of resources and their
respective differences in revenue.

### API

#### Totals versus Full Sets

The endpoint `/res_diff` will return the count of resources matching
the conditions as an integer.
The endpoint `/res_diff/resources` will return a JSON representation
of the resources themselves as an array of hashes.  

#### Periods of Comparison

This endpoint will compute differences between two periods of time. Thus the API
expects 4 time parameters. 2 parameters to represent the first period and 2
parameters to represent the second period.

#### Direction of Difference

In addition to timestamps, the API also
expects a parameter indicating if the delta of the difference is increasing or decreasing. 
Results with no difference are inherently excluded from the result set.  This
means the results are either all increasing or all decreasing which allows the
paramter to be specified as an invariant.

#### Starting & Ending Revenue

Some resources will have a starting revenue of $0.00 and end with a
revenue of $100.00. Likewise start with $100.00 and end with $0.00.

As of now, the only interesting conditions occur when the revenue values are 
either zero or non-zero.  This is specified via parameters as the invariants 
`lrev_zero` and `rrev_zero`.

#### Limiting Result Set

On a production installation, the number of results from the API
will be quite numerous.  Instead of supporting pagination with a limit
and offset parameter, the `/res_diff/resources` endpoint will sort 
its results descending by delta.  The limit parameter will take the
top N results from this list.  

#### Boolean parameters

Boolean parameters can be encoded as the following:

* True: 1, t, or true (case insensitive)
* False: 0, f, or false (case insensitive)

#### Examples

```bash
$ curl -X GET \
  "https://provider:token@shushu.heroku.com/res_diff? \
  lfrom=time& \
  lto=time&   \
  rfrom=time& \
  rto=time&   \
  delta_increasing=bool&   \
  lrev_zero=bool&   \
  rrev_zero=bool"

  123

$ curl -X GET \
  "https://provider:token@shushu.heroku.com/res_diff/resources? \
  lfrom=time& \
  lto=time&   \
  rfrom=time& \
  rto=time&   \
  delta_increasing=bool&   \
  lrev_zero=bool&   \
  rrev_zero=bool&   \
  limit=int"

[
  {"resource": "resource123@heroku.com", "lrev": 1000.0, "rrev": 0.0, "diff": -1000.0},
  {"resource": "resource124@heroku.com", "lrev": 0.0, "rrev": 10.0, "diff": 10.0}
]
```

## Revenue Report

Revenue is computed by looking at all billable_events that spane a given period,
scoping the billable_events within the specified period, grouping them by rate,
summing the quantity within the groups, and finally taking a sum of the product
of grouped, sumed quantities with their respective rates.

### Quantity Based Credits

Heroku issues a quantity based credit. For instance, all resources receive
750 free hours for a particular rate_code. The 750hrs is a parameter to the
revenue report.

### API

```bash
$ curl -X GET "https://provider:token@shushu.heroku.com/rev_report? \
  from=time&
  to=time&
  qcredit=int"

{"total": 12345.00}
```
