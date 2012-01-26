# PaymentMethod API

While the [account](https://github.com/heroku/shushud/blob/master/doc/accounts_api.md)
represents an aggregation of resources, the payment_method
represents an aggregation of accounts. Also, similar to the account's
usage_report, the payment_method is required to produce an invoice. As noted in
the reports documentation, the invoice represents a dollar amount that will
eventually be represented by a receivable while the usage_report will have no
relationship to a receivable. Thus, a payment_method is required for invoice
generation and subsequently receivable generation. Also, it should be noted that
the accounts can belong to the same payment_method by creating account_ownerhips
records. See the [AccountOwnership API](https://github.com/heroku/shushud/blob/master/doc/account_ownership_api.md)
for more details.

## API

### Create PaymentMethod

#### Using a card token without id

You can rely on Shushu creating an id for the payment_method. Use the POST
endpoint to rely on the generated id.

```bash
$ curl -X POST https://123:secret@shushu.heroku.com/payment_methods \
  -d "card_token=abc123"

{"id": "0001", "token": "abc123"}
```

#### Using a card token with id

If you already have an id for the payment_method, you can use the PUT endpoint
to create the payment_method. Of course this endpoint has idempotent attributes
with respect to the supplied id. The id can be any arbitrary string and it's
uniqueness will be scoped to the provider who submitted the request.

```bash
$ curl -X PUT https://123:secret@shushu.heroku.com/payment_methods/id@yourdomain.com \
  -d "card_token=abc123"

{"id": "id@yourdomain.com", "token": "abc123"}
```


#### Using a encrypted credit card number with id

**Deprecation Warning**

Eventually, this API will only accept card tokens. It should be noted by the FDP
model that resolving credit cards is fit for something in L1 & L2. Until Heorku
figures out a good story for were to put credit card resolution, it will remain
here.

```bash
$ curl -X POST https://123:secret@shushu.heroku.com/payment_methods \
  -d "card_num=encrypted card number"                               \
  -d "card_exp_year=2012"                                           \
  -d "card_exp_month=02"

{"id": "0001", "token": "abc123", "card_type": "visa", "card_last4": "4111"}
```

#### Using a encrypted credit card number with id

```bash
$ curl -X PUT https://123:secret@shushu.heroku.com/payment_methods/id@yourdomain.com \
  -d "card_num=encrypted card number"                                                \
  -d "card_exp_year=2012"                                                            \
  -d "card_exp_month=02"

{"id": "id@yourdomain.com", "token": "abc123", "card_type": "visa", "card_last4": "4111"}
```


### Update PaymentMethod

#### Non-receivable

Not all payment_methods will represent a receivable. For instance, you may want
to allow the employees of an organization use the org's services without charge.
When it comes time to generate receivable, if the payment_method of a group of
accounts is maked as a non-receivable, then it will be skipped an the receivable
revenue number will not be impacted.

```bash
$ curl -X PUT https://123:secret@shushu.heroku.com/payment_methods/id@yourdomain.com \
  -d "non-receivable=true"

{"id": "id@yourdomain.com", "token": "abc123", "non-receivable": true}
```

#### New token

```bash
$ curl -X PUT https://123:secret@shushu.heroku.com/payment_methods/id@yourdomain.com \
  -d "card_token=abc124"

{"id": "id@yourdomain.com", "token": "abc124"}
```

#### New credit card number

```bash
$ curl -X PUT https://123:secret@shushu.heroku.com/payment_methods/id@yourdomain.com \
  -d "card_num=encrypted card number"                                                \
  -d "card_exp_year=2012"                                                            \
  -d "card_exp_month=02"

{"id": "id@yourdomain.com", "token": "abc124", "card_type": "amex", "card_last4": "3333"}
```
