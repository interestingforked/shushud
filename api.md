# Shushud API Documentation

* Provider
* RateCode
* BillableEvent
* ResourceOwnership
* ResourceHistory

## Provider

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

## RateCode

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
