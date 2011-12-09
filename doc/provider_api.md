# Provider API

## Purpose

Shushu will not accept billable events from untrusted sources. In fact,
all of the endpoints in the Shushu API require authentication against
the provider ID and the provider token.

## API

Currently, providers can only be created on a ruby console of using the database
client. Programatic creation of providers is not yet supported.
