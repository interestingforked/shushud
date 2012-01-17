# Security

## Authentication

Each endpoint requires authentication. The API will authenticate against a
guessable provider_id and a non-guessable provider_token. The provider_token
will be generated on the Shushu console and then distributed to each provider on
an individual basis. Each provider will have a row in Shushu's database. Each
row will have a token column that will contain the result of a hashing function
with respect to the provider_token.

To reset a token for a provider, the following command should be issued on the
Shushu console:

```ruby
new_token = SecureRandom.hex(128)
provider.reset_token!(new_token)
puts "Provider's new token: #{new_token}"
```

The provider will then need to know it's **id** & **token**. Using this
information, the provider can then authenticate.

### HTTP Basic

First, the provider must establish a session.

```bash
$ curl -X GET http://12348:mytoken@shushu.heroku.com/heartbeat
```

### Cookie

Once a session has been established, the cookie may be used to authenticate
further requests.

```bash
$ curl -X POST http://shushu.heroku.com/some_endpoint
  --cookie shushu.session==some_random_string_from_an_earlier_request
```

## Stopping a rouge provider

There may be a time when a provider has gone rouge and is submitting false
events. The thing to do in this situation is stop them from submitting further
requests and then to invalidate all of the event's that were submitted in the
compromised frame of time.

To stop a provider from submitting a request, issue the following command on the
Shushu console:

```ruby
provider = Provider[12348]
provider.disable!
```

The following command will remove their session from memcached and stop them
from authenticating. Their authentication will be halted based upon a boolean
column on the row of the provider in the providers table.
