# 収集

## Setup

https://github.com/heroku/shushu/blob/master/setup.md

## Purpose

Collect Billable Events.

Providers like Sendgrid need a more robust way to charge customers. The Vault will provide a mechanism for add-on providers that allows them to notify us of billable events. We will append these events to our durable log and then convert them into line items which will eventually wind up on an invoice.

This API will also serve as the canonical source for all billable events in the cloud. Depending upon the success of our rollout to add-on providers, we hope the adoption of the API will reach teams like runtime and add-ons.

## General Idea

If you tell me about an event that I do not already know about --fine. If you
tell me that an event I know about has changed, it can only be that the event
has ended. You can tell me about an event as much as you would like so long as
the details remain constant.


## Concerns

**Time sensitive data**

In order to maintain real-time invoices, The Vault requires provider data ASAP. To do this we will ask the provider to PUT billable events to our API within a specified time frame. Events will fail validation if the PUT occurs at a time that is 6 hours greater than the event's created_at field.

The Vault will also invalidate events that are submitted 6 hours after the end of a period. The end of a period is most often the final second in a month.

Valid times are calculated with respect to US/Pacific.

**Rate codes**

Each event submitted by a provider will require a rate_code. This code represents the provider's 
agreement with add-ons. The code will have an associated description and rate. 
For example, Sendgrid may have the code `SG001` and this code represents email overages 
and has a rate of $0.05. If a customer sends an additional 100 emails in a period, 
Sendgrid may PUT an event with `{'qty': 100, 'rate_code': 'SG001', ...}`

## API Set

*The following APIs are idempotent.*

### Create Event

The Provider wants to create a new event. This API is idempotent; however, a unique error code (409) is returned in the case you attempt to modify an existing attribute.


**Provider PUT Request**

```
PUT /resources/app123@heroku.com/billable_events/event_id
{'qty': N, 'created_at': 't1', 'ended_at': nil, 'rate_code': M }
```

**The Vault Response**

```
200 - Event has already been created.
201 - Event created. Event included in the current invoice period.
409 - Event has already been created. ended_at is the only attribute available for change.
412 - You are too late in reporting this event. #=> (created_at - Time.now).abs > 7.hours
412 - Event submitted past cut-off time.
422 - Rate code was not found.
422 - Rate code is inactive.
422 - Created time occurred after resource de-provision.
```
### Close Event

There are certain rate codes that allow the ended_at column to be updated. For instance, Psmgr may wish to stop billing for an event. If you have already created the event with id = event_id and you PUT attributes that are different than the recorded attributes, your will receive a 409 error.

**Provider PUT Request**

```
PUT /resources/app123@heroku.com/billable_events/event_id
{'qty': N, 'created_at': 't1', 'ended_at': 't2', 'rate_code': M }
```

**The Vault Response**

```
200 - Event has been ended.
409 - Event has already been created. ended_at is the only attribute available for change.
422 - Rate code does not allow the setting of ended_at.
```

### Delete

The provider has made a mistake. There are certain rate codes that allow an event to be deleted.

**Provider DELETE Request**

```
DELETE /resources/app123@heroku.com/billable_events/event_id
```

**The Vault Response**

```
200 - Event will be removed from the invoice.
422 - Event is not allowed to be removed.
```

## HA

These APIs will be maintained with meticulous care. However, they may be offline at some point in time.

### General Error

**The Vault Response**

```
500 - The fan is dirty.
```

### Maintenance

There may be time when we have to migrate a schema or change implementation of API.

**The Vault Response**

```
503 - Try again.
```
## Authentication

HTTPS Basic Authentication. Each provier will be issued an ID and a token. 

```bash
$ curl https://ID:TOKEN@shushu.heroku.com/whatever...
```

## Notes

The majority of this API design was inspired by couchdb's HTTP API.
http://wiki.apache.org/couchdb/HTTP_Document_API#PUT
