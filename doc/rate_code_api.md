# Rate Code API

## Purpose

The rate code provides an abstraction between events and costs associated with events.
Rate codes also reduce the burdon of the Shushu client in that the client does not
have to repeat rate codes when sending events.

## API

### Authentication

**HTTP Basic**

This API uses authentication similar to the rest of Shushu's API: provider_id:provider_token. 
However, there is authorization on  this API. A special bit is required to write rate codes.
This mechanism will allow the Add-ons Team to properly filter who is creating rate_codes.

### Create Rate Code (POST)

Before you can create billable_events, you must create a rate code for the event. 
Depending on your provider credentials, you may have to wait for rate_code approval.

```bash
$ curl -X POST https://provider_id:provider_token@shushu.heroku.com/rate_codes -d rate=5 -d description=dyno-hour
{
  'slug': 'RT01',
  'status': 'active',
  'rate': '5',
  'description': 'dyno-hour'
  'billable_events': '0'
}
```

It is possible for a provider to create a rate code on behalf of another provider. This is 
particularly useful for the add-ons team. This features requires a special bit on the provider.

```bash
$ curl -X POST https://provider_id:provider_token@shushu.heroku.com/providers/:target_provier_id/rate_codes \b
               -d rate=5 \
               -d description=dyno-hour \
```

### View Rate Code (GET)

This endpoint provides general information about the rate code.

**slug**: <String> ID that provider & Shushu know about

**status**: <String> State of the rate code. Possible values: active, inactive.

**rate**: <Integer> The number of pennies this event should costs per hour.

**description**: <String> How the event will be described in the Invoice.

**billable_events**: <Integer> How many events are keyed to this rate_code.


```bash
$ curl https://provider_id:provider_token@shushu.heroku.com/rate_codes/:rate_code_slug

{
  'slug': 'RT01',
  'status': 'active',
  'rate': '5',
  'description': 'dyno-hour'
  'billable_events': 'number of billable events with this rate code'
}
```

### Update the Rate Code (PUT)

Lets say that you created a rate code and then started created billable_events for the rate code.
Moments later you realize that you have entered an incorrect rate for the rate code. 
Instead of modifying the billable_events, you can simply update the rate on the rate_code.

```bash
$ curl -X PUT https://provider_id:provider_token@shushu.heroku.com/rate_codes/:rate_code_slug -d rate=10

{
  'slug': 'RT01',
  'status': 'active',
  'rate': '10',
  'description': 'dyno-hour'
  'billable_events': 'number of billable events with this rate code'
}
```