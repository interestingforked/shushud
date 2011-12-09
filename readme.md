# 収集

## Purpose

Collect Billable Events.

Providers like Sendgrid need a more robust way to charge customers.
The Vault will provide a mechanism for add-on providers that allows them
to notify us of billable events. We will append these events to our durable log
and then convert them into billable units which will eventually wind up on an invoice.

This API will also serve as the canonical source for all billable events in the cloud.
Depending upon the success of our rollout to add-on providers, we hope the adoption
of the API will reach teams like runtime and add-ons.

## Setup

https://github.com/heroku/shushu/blob/master/setup.md

## API Documentation

* [billable events](https://github.com/heroku/shushu/blob/master/doc/events_api.md)
* [rate codes](https://github.com/heroku/shushu/blob/master/doc/rate_code_api.md)
* [provider](https://github.com/heroku/shushu/blob/master/doc/provider_api.md)
* [resource ownership](https://github.com/heroku/shushu/blob/master/doc/resource_ownership_api.md)
