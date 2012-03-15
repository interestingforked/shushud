# Rate Code API

## Purpose

Before a provider can submit billable events to Shushu,
a rate code must be established. The rate_code's slug
should be passed along with the billable event. The rate
code will contain information like the rate in cents,
the period in which the rate code should be applied,
the product group and product name.

## API

### Create Rate Code

Rate codes will be identified by the slug. You can provide a slug or Shushu will generate a slug on the provider's behalf. The generated slug will be in a UUID form and any provided slug should be in UUID form as well.

**Shushu Generated Slug**

```bash
$ curl -X POST https://shushu.heroku.com/rate_codes \
  -d "rate=5"     \
  -d "group=dyno" \
  -d "name=web"

{"slug": "13f9b848-d636-475f-b47b-42783f5fc9f9", "rate": "5", "group": "dyno" "name": "web"}
```

**Provider Generated Slug**

```bash
$ curl -X PUT https://shushu.heroku.com/rate_codes/13f9b848-d636-475f-b47b-42783f5fc9f9 \
  -d "rate=5"     \
  -d "group=dyno" \
  -d "name=web"

{"slug": "13f9b848-d636-475f-b47b-42783f5fc9f9", "rate": "5", "group": "dyno" "name": "web"}
```

## Issues

Currently this API does not support the updating of rate_codes. An argument can be made for supporting updates in the caes of a rate changing. Currently if a provider wanted to change the rates of billable events, a new rate_code would have to be created and all of the billable_events associated with the old rate would have to be closed and new ones opened with the new rate code.
