# Shushu's HTTP API

All of Shushu's services are made available over an HTTP API.

## Authentication

All API endpoints require authentication. The API requires HTTP Basic
Authentication over SSL. All non-SSL requests will be redirected to HTTPS.

## Time

All of the APIs in Shushu rely on the client's time. Times should be sent in
is8601 compatible format. I will use timestamps like: 2012-01-01 00:00:00 UTC,
throughout the documentation. Shushu does keep track of internal time of
changes, however, client's should not rely upon any time that Shushu
maintians.

## Entity IDs

An entity_id is client generated token that is used to represent an entity in the
client's system. Shushu requires this ID to cluster groups of events.

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

Now, if record1 had entity_id=001, and when you told me about record2, you
included entity_id=002 as the previous entity_id and entity_id=003 as the new
entity_id , I can now systematically deduce that I am in an erroneous state.

Therefore, entity_ids help Shushu in preventing monetary actions on unreliable
data.
