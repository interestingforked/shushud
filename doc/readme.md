# The Vault's API

## HTTP Status Codes

This API will use the following status codes. Also, I have included
troubleshooting tips to the code.

* 200 - OK.
* 201 - We created a record.
* 400 - Are you using http basic?
* 401 - Are you using the correct authentication parameters?
* 403 - Are you doing something that requires root provider status?
* 404 - Did you send the correct rate_code slug?
* 422 - Was not able to save the record. Could be someting semantically wrong with the http body.
* 500 - Sorry.
