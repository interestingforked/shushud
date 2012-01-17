# Security

## Authentication

All API endpoints require authentication. The parameters used to authenticate
are the id of your provider record and the record's unencrypted token.

### HTTP Basic

```bash
$ curl -X GET http://12348:mytoken@shushu.heroku.com/heartbeat
```
### Cookie

```bash
$ curl -X POST http://shushu.heroku.com/some_endpoint
  --cookie rack.session=some_random_string_from_an_earlier_request
```
