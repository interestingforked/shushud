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
* Track account/credit card interactions.
* Allow easy computation of revenue.
* Provide hooks for failure/success events.
* Shouldn't care too much about the gateway.
* Should be scriptable and have a good web UI.

## API

### Create Receivable

This endpoint will create a new receivable row in the database if there is not already a
row with the given payment_id & period.

**Arguments:**

* payment_method_id   - This payment_method will be used to capture funds.
* amount              - An integer representing the amount in pennies.
* from
* to

```bash
$ curl -X POST https://shushu.heroku.com/receivables \
  -d "init_payment_method_id=123" \
  -d "amount=1000" \
  -d "from=2012-01-00" \
  -d "to=2012-02-00"
```

**Respnoses:**

* 200 - Receivable exists. Nothing to do.
* 201 - Receivable created.

```
{
  "receivable_id": 123,
  "init_payment_method_id": 456,
  "amount": 1000,
  "state": "pending",
  "from": "2012-01-01",
  "to": "2012-02-01"
}
```

### Create PaymentAttempt

Once a receivable has been created, an attempt must be created in order to capture
funds from the initial payment_method. It should be noted that you can create an
attempt using a payment_method_id that is different than the receivable's
init_payment_method_id. This allows a customer with a bad payment_method to
create a new payment_method and then settle his outstanding receivables. The
client should validate that the correct payment_method is paying for the correct
receivable.

**Arguments:**

* payment_method_id - Use this payment_method to capture. Can be different than receivable's init_payment_method
* wait_until - Must be greater than the payment's created_at. If blank, request is handled sync.
* retry - Set this to false if you want to override the rety logic.
* force - Ignore the success probability check and force create attempt.

```bash
$ curl -X POST https://shushu.heorku.com/receivables/123/payment_attempts \
  -d "payment_method_id=456" \
  -d "wait_until": "2011-12-01 00:00:01 UTC" \
  -d "retry=true" \
  -d "force=true"
```

**Responses:**

* 201 - Attempt has been created.
* 404 - Not created. Could not find receivable with the given receivable_id.
* 422 - Not created. Account action required. Most likely need credit card update.

Sync Capture. Failed. Retry eligible.

```
[
  {
    "receivable_id": 123,
    "payment_method_id": 456,
    "state": "failed-no-act-req",
    "wait_until": null,
    "time": "2011-12-01 00:00:01 UTC",
    "gateway_resp": "Some text..."
  },
  {
    "receivable_id": 123,
    "payment_method_id": 456,
    "state": "ready",
    "wait_until": "2011-12-05 00:00:00 UTC",
    "time": "2011-12-01 00:00:01 UTC",
    "gateway_resp": null
  }
]
```

Capture Later.

```
{
  "receivable_id": 123,
  "payment_method_id": 456,
  "state": "ready",
  "wait_until": "2011-12-05 00:00:00 UTC",
  "time": "2011-12-01 00:00:00 UTC",
  "gateway_resp": null
}
```

### Query Payment Attempts

```bash
# View payment_attempts
$ curl -X GET https://shushu.heroku.com/receivables/12345/payment_attempts
```

**Responses:**

```
{
  [
    {
      "receivable_id": 123,
      "payment_method_id": 456,
      "state": "ready",
      "wait_until": "2011-12-05 00:00:00 UTC",
      "time": "2011-12-01 00:00:00 UTC",
      "gateway_resp": null
    },
    {
      "receivable_id": 123,
      "payment_method_id": 456,
      "state": "succeeded",
      "wait_until": null,
      "time": "2011-12-05 00:00:01 UTC",
      "gateway_resp": "great success"
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
    account.attempt_all_past_due_receivables
  end

end
```
