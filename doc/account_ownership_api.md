# Account Ownership Events API

## Purpose

Heroku customers want to pay for multiple accounts with one credit card. Heroku
customers may also want to transfer payment to another credit card. In this
case, the previous credit card should be charged for the time until it was
transfered to the other credit card.

Invoices for accounts should not be impacted by changes with credit cards. For
instance, if a heroku team member is looking at an account invoice that has
changed credit cards over a period, those changes should not be visible to the
team invoice.

Receipts for credit cards should include details involving the changes of credit
cards in their invoice.

## API

### Activate

In order to build an invoice for a payment method, the payment method
must be associated with one or more accounts. This API endpoint
will allow you to activate the association.

If no account can be found using the :account_id, Shushu will create one
during the resource_ownership request.

```bash
$ curl -X POST https://shushu.heroku.com/payment_methods/:payment_method_id/account_ownerships/:entity_id \
  -d "state=active"                 \
  -d "account_id=987"               \
  -d "time=1999-12-31 00:00:00 UTC"

{"payment_method_id": "123", "account_id": "987", "entity_id": "456", "state": "active"}
```

### Deactivate

When an account no longer belongs to a payment method, or if an account is
to be moved to another payment method, the prior relationship must be
deactivated.

```bash
$ curl -X POST https://shushu.heroku.com/payment_methods/:payment_method_id/account_ownerships/:entity_id \
  -d "state=inactive"               \
  -d "account_id=987"               \
  -d "time=1999-12-31 00:00:00 UTC"

{"payment_method_id": "123", "account_id": "987", "entity_id": "456", "state": "active"}
```
