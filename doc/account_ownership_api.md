# Account Ownership API

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

In order to build an invoice for a payment method, the payment method must be associated with one or
more accounts. This API endpoint will allow you to activate the association.

```bash
$ curl -i -X POST https://shushu.heroku.com/payment_methods/:payment_method_id/account_ownerships/:event_id \
  -d "account_id=987"
  -d "time=1999-12-31 00:00:00 UTC"
```

**Responses**

* 201 - The payment method is now associated with the given account.
* 404 - Account not found.
* 409 - This association already exists.

```
{"payment_method_id": "123", "account_id": "987", "event_id": "456", "state": "active"}
```

### Transfer

This endpoint facilitates the changing of a payment method for an account. This
is useful when you want to change the payment method for a Heorku team for
instance.

When an account is transfered to another payment_method, the invoice will
reflect the change by accruing charges for both payment_methods during their
respective ownership periods. However, usage reports will remain unchanged.

```bash
$ curl -i -X POST https://shushu.heroku.com/payment_methods/:prev_payment_method_id/account_ownerships/:prev_event_id \
  -d "account_id=654"
  -d "time=2000-01-01 00:00:00 UTC"
```

**Responses**

* 201 - The payment method is now associated with the given account.
* 404 - Account not found.
* 409 - This association already exists.

```
{"payment_method_id": "123", "account_id": "654", "event_id": "333", "state": "active"}
```
