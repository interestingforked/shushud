# 収集

* purpose
* name
* setup
* api

## Purpose

* Track and store billable_events in an append-only log.
* Track and store resource ownerships.
* Manage rate codes for billable events.

## Name

Shushu is japanese for collector. Shushu collects and maintains all data related
to usage & billing.

## Setup

```bash
$ export $(cat sample.env)
$ bundle install
$ bin/db-reset
$ bin/web
$ curl -i -X HEAD https://localhost:$PORT/
```

```bash
$ export $(cat sample.env)
$ bundle install
$ bin/db-reset test
$ bundle exec turn/test
```

## API

* [Provider](#provider)
* [RateCode](#ratecode)
* [BillableEvent](#billablevent)
* [ResourceOwnership](#resourceownership)
* [ResourceHistory](#resourcehistory)

### Provider

All API endpoints require that you authenticate with your provider credentials. To create a provider, use the `create-provider` bin.

```bash
$ bundle exec bin/create-provider $name $token
id=123
token=$token
```

* id - Unique integer representing your provider.
* name - Non-unique string for human representation.
* token - Unguessable string. Leave it blank and Shushud will generate one on your behalf.

You will authenticate using the id as the HTTP basic user and the token as the HTTP basic password. For instance:

```bash
$ curl https://$id:$token@shushud.herokuapp.com/heartbeat
```

### RateCode

You will need a rate code slug to create billable events. You can provider an id for the rate code or Shushud will generate one on your behalf.

```bash
$ curl -X POST https://$id:$token@shushud.herokuapp.com/rate_codes \
	-d "rate=100" \
	-d "period=month" \
	-d "group=addon" \
	-d "name=database"
{"id":1,
  "provider_id":1,
  "created_at":"2012-08-31 04:34:39 UTC",
  "rate":100,
  "rate_period":"month",
  "slug":"722adf59-940a-49d2-bd54-6a52ef12da23",
  "product_group":"addon",
  "product_name":"database"}
```

```bash
$ curl -X PUT https://$id:$token@shushud.herokuapp.com/rate_codes/myslug \
	-d "rate=100" \
	-d "period=month" \
	-d "group=addon" \
	-d "name=database"
{"id":1,
  "provider_id":1,
  "created_at":"2012-08-31 04:34:39 UTC",
  "rate":100,
  "rate_period":"month",
  "slug":"myslug",
  "product_group":"addon",
  "product_name":"database"}
```

* rate - Integer. Pennies. Will be included in ResourceHistory report for monetary summations.
* rate_period - String. Must be 'month' or 'hour'.
* slug - String. Your identification for the RateCode.
* product_group - String. Top level product taxonomy.
* product_name - String. Bottom level product taxonomy.

### BillableEvent

Once you have created a Provider and a RateCode, you can star creating BillableEvents. You must open an event before it can be closed. If your open/close messages are in a buffer, there is no harm in repeted attempts to close an event before it has been opened.

```bash
$ curl -X PUT "https://$id:$token@shushud.herokuapp.com/resources/123/billable_events/722adf59-940a-49d2-bd54-6a52ef12da23" \
	-d "rate_code=myslug" \
	-d "product_name=database" \
	-d "description=pg-9.2" \
	-d "qty=1" \
	-d "time=2012-08-31 04:34:39" \
	-d "state=open"
{"id":"722adf59-940a-49d2-bd54-6a52ef12da23"}
```

### ResourceOwnership

Owners are not tracked in shushu. You invioce system will probably have the ID for the owner. This system can be one that you have built or something like Stripe. Nevertheless, you will want to associate owners with resources. This is how you will connect invoices and usage data.

```bash
$ curl -X PUT "https://$id:$token@shushud.herokuapp.com/accounts/owner-id/resource_ownerships/entity-id" \
	-d "resource_id=123" \
	-d "state=active" \
	-d "time=2012-08-31 04:34:39"
{"id":"722adf59-940a-49d2-bd54-6a52ef12da23"}
```

### ResourceHistory

This endpoint will return a summary report for an owner.

```bash
$ curl -X GET "https://$id:$token@shushud.herokuapp.com/owners/owner-id/resource_summaries" \
	-d "from=2012-08-01" \
	-d "to=2012-09-01"
[{"123":[{
	"product_group":"addon",
	"product_name":"database",
	"description":"",
	"qty":41.0,
	"daily_avgs":[0.7083333333333334,1.0]}]}]
```
