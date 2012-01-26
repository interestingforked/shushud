# PaymentMethod API

While the [account] represents an aggregation of resources, the payment_method
represents an aggregation of accounts. Also, similar to the account's
usage_report, the payment_method is required to produce an invoice. As noted in
the reports documentation, the invoice represents a dollar amount that will
eventually be represented by a receivable while the usage_report will have no
relationship to a receivable. Thus, a payment_method is required for invoice
generation and subsequently receivable generation. Also, it should be noted that
the accounts can belong to the same payment_method by creating account_ownerhips
records. See the [AccountOwnership API] for more details.

## API

### Create PaymentMethod

#### Using a card token

#### Using a encrypted credit card number

**Deprecation Warning**

Eventually, this API will only accept card tokens. It should be noted by the FDP
model that resolving credit cards is fit for something in L1 & L2. Until Heorku
figures out a good story for were to put credit card resolution, it will remain
here.

### Update PaymentMethod

#### Non-receivable

Not all payment_methods will represent a receivable. For instance, you may want
to allow the employees of an organization use the org's services without charge.
When it comes time to generate receivable, if the payment_method of a group of
accounts is maked as a non-receivable, then it will be skipped an the receivable
revenue number will not be impacted.


#### New token

#### New credit card number
