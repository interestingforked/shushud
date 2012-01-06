# Payments

## Purpose

So you got an invoice, now you want to get some money for it.
Posting a transaction to a payment gateway is only one of the things involved in
managing customer payments. In order to effectively manage this data we must
consider the following:

* Eliminate possibility of duplicate charge.
* Do not attempt to charge a card that has a 0 probability of success.
* Rule based auto-capture.
* Handle refunds.
* Allow multiple payments on 1 invoice.
* Track account/credit card interactions.
* Allow easy computation of revenue.
* Provide hooks for failure/success events.
* Shouldn't care too much about the gateway.
* Should be scriptable and have a good web UI.

## Synopsis

```
PaymentMethod -1---n->    CardTokens      * such that 1 token is active
Payment       -1---n->    PaymentAttempts
```

## The API

### Create Payment

This endpoint will create a new payment row in the database if there is not already a
row with the given invoice_id.

**Arguments:**

* payment_method_id   - This payment_method will be used to capture funds.
* invoice_id          - Used only for reference.
* amount              - An integer representing the amount in pennies.

```bash
$ curl -X POST https://shushu.heroku.com/payments \
  -d "payment_method_id=123" \
  -d "invoice_id=456" \
  -d "amount=1000"
```

**Possible Respnoses:**

* 200 - Payment exists. Nothing to do.
* 201 - Payment created.

```
{
  "payment_id": 123,
  "invoice_id": 456,
  "amount": 1000,
  "state": "pending",
  "transitioned_at": "2011-12-01 00:00:00 UTC"
}
```

### Create PaymentAttempt

Once a payment has been created, an attempt must be created in order to capture
funds from the payment_method.

**Arguments:**

* amount - must be less than payment amount. If blank, uses the payment's amount.
* capture_at - must be greater than the payment's created_at. If blank, request is handled sync.
* rety - set this to false if you want to override the rety logic.
* force - ignore the success probability check and force create attempt.

```bash
$ curl -X POST https://shushu.heorku.com/payments/123/payment_attempts \
  -d "amount=1000" \
  -d "capture_at": "2011-12-01 00:00:01 UTC"
```

**Possible Responses:**

* 201 - Attempt has been created.
* 400 - Not created. Contains amount which is greater than the amount of Payment.
* 404 - Not created. Could not find payment with given payment_id.
* 422 - Not created. Account action required. Most likely need credit card update.

Capture Now. Failed. Retry eligible.

```
[
  {
    "payment_id": 123,
    "amount": 1000,
    "state": "failed-no-act-req",
    "created_at": "2011-12-01 00:00:00 UTC",
    "capture_at": "2011-12-01 00:00:01 UTC",
    "captured_at": "2011-12-01 00:00:02 UTC",
    "gateway_resp": "Some text..."
  },
  {
    "payment_id": 123,
    "amount": 1000,
    "state": "pending-capture",
    "created_at": "2011-12-01 00:00:03 UTC",
    "capture_at": "2011-12-05 00:00:03 UTC",
    "captured_at": null,
    "gateway_resp": null
  },
]
```

Capture Later.

```
{
  "payment_id": 123,
  "amount": 1000,
  "state": "pending-capture",
  "created_at": "2011-12-01 00:00:00 UTC",
  "capture_at": "2011-12-01 00:00:10 UTC",
  "captured_at": null,
  "gateway_resp": null
}
```

### Query Payment Attempts

```bash
# View payment_attempts
$ curl -X GET https://shushu.heroku.com/payments/12345/payment_attempts
{
  [
    {
      "payment_id": 123,
      "created_at": "2011-12-12 00:12:00 UTC",
      "capture_at": "2011-12-12 00:12:00 UTC",
      "captured_at": "2011-12-12 00:12:01 UTC",
      "amount": 1000,
      "state": "failed-no-action-req"
    },
    {
      "payment_id": 123,
      "created_at": "2011-12-12 00:12:02 UTC",
      "capture_at": "2011-12-16 00:12:00 UTC",
      "captured_at": "2011-12-16 00:12:01 UTC",
      "amount": 1000,
      "state": "succeeded"
    }
  ]
}
```


### Events

Shushu::Payments employs a state machine that allows arbitrary code blocks to be
executed upon state transition.

This DSL is located within the config dir of Shushu and should be configured
there.

```ruby
Shushu::Payments.setup do

  when(:actionable_failure) do |failure, attempt|
    Mailer.send_notice(failure, attempt)
  end

  when(:non_actionable_failure) do |failure, attempt|
    Mailer.send_notice(failure, attempt)
    PaymentAttempt.create(:capture_at => Time.now + 4.days)
  end

  when(:updated_credit_card) do |account|
    account.retry_all_failed_payments
  end

end
```
