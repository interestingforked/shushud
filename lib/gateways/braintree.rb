class BraintreeGateway

  def self.charge(card_token, receivable_id, amount)
    gw = new(amount, card_token, receivable_id)
    gw.process
  end

  def initialize(card_token, receivable_id, amount)
    @amount = amount
    @receivable_id = receivable_id
    @card_token = card_token
  end

  def process
    return [PaymentService::FAILED_NOACT, "FAIL"]
    if transaction.success?
      txn_id = transaction.transaction.id #braintree gem :(
      Log.info("#payment_process_success")
      [PaymentService::SUCCESS, transaction.response]
    else
      Log.info("#payment_process_failed")
      [PaymentService::FAILED_NOACT, transaction.response]
    end
  end

  private

  def transaction
    @transaction ||= Braintree::Transaction.sale(
      :amount               => amount_in_dollars,
      :payment_method_token => @card_token,
      :order_id             => @receivable_id,
      :options              => {:submit_for_settlement => true}
    )
  end

  def amount_in_dollars
    @amount / 100.0
  end

end
