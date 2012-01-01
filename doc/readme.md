# The Vault's HTTP API

All of The Vault's services are made available over an HTTP API.

## Authentication

All API endpoints require authentication. The API requires HTTP Basic
Authentication over SSL. All non-SSL requests will be redirected to HTTPS.

## Distributed Systems

If you are working with this API, you are participating in a distributed system.
Needless to say, with great power comes great responsibility. There are many
things to be concerned with, however there are a couple of issues in particular that I
would like to address now.

### Event IDs

There are several APIs in Shushu that deal with records that live in a FSM. You
will be opening and closing billable_events, activating and de-activating
account ownership records and so on...

When working with this type of data, it is
handy to think of the state transitions as statements in a transaction. Thus, to
ensure that we properly deal with the transaction, the API requires that you
submit an ID that will identify the transaction upon each request. You, the
client of this API, will be responsible for remembering the ID.

Think of what might happen if we did not have such an ID. Lets say that we are
dealing with a resource ownership record. This record knows who owned what and
for how long. So you tell Shushu that account=1 owns resource=a at time=1, call
this record1. Next you tell me that account=2 owns resource=a at time=2, record2.
Using the timestamps in record1 and record2, I can deduce that record1 begins at
time=1 and ends at time=2. Independently, I may charge customers accounts based
on my deduced knowledge that record1 begins at time=1 and ends at time=2. This
is dangerous! Lets say that in between record1 and record2 there was record1.5.
Further lets suppose that when you made and HTTP request to inform me of
record1.5, our connection was partitioned and I never acknowledged. This means
that I incorrectly charged a customers account and based on my data I had no way
of knowing that I was in an erroneous state.

Now, if record1 had event_id=001, and when you told me about record2, you
included event_id=002 as the previous event_id and event_id=003 as the new id, I
can now systematically deduce that I am missing date.

Therefore, event ids aid Shushu in keeping reliable data.

## HTTP Status Codes

This API will use the following status codes. Also included our some
troubleshooting tips.

* 200 - OK.
* 201 - We created a record.
* 400 - Are you using http basic?
* 401 - Are you using the correct authentication parameters?
* 403 - Are you doing something that requires root provider status?
* 404 - Did you send the correct rate_code slug or account_id?
* 422 - Was not able to save the record. Could be something semantically wrong with the http body.
* 500 - Sorry.
