class BraintreeGateway

  FAILMAP = {
    "2004" => PaymentService::FAILED_ACT,   #expired card
    "2043" => PaymentService::FAILED_ACT,   #error do not retry
    "2044" => PaymentService::FAILED_ACT,   #declined call issuer
    "2047" => PaymentService::FAILED_ACT,   #call issuer, pick up card
    "2046" => PaymentService::FAILED_NOACT, #general decline
    "2001" => PaymentService::FAILED_NOACT, #insufficient funds
    "2011" => PaymentService::FAILED_NOACT, #voice auth required
    "2015" => PaymentService::FAILED_NOACT, #txn not allowed
  }

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
    #FIXME temp measure
    return [PaymentService::FAILED_NOACT, "FAIL"]

    if transaction.success?
      txn_id = transaction.transaction.id #braintree gem :(
      Log.info("#payment_process_success")
      [PaymentService::SUCCESS, transaction.response]
    else
      handle_failure
    end
  end

  private

  def handle_failure
    if transaction.transaction.status == "processor_declined"
      code = transaction.transaction.processor_response_code
      text = transaction.transaction.processor_response_text
      state = FAILMAP[code] || PaymentService::FAILED_NOACT
      Log.info("#payment_process_failed code=#{code} text=#{text} attempt_state=#{state}")
      [state, text]
    else
      Log.info("#payment_gateway_failed")
      [PaymentService::FAILED_NOACT, transaction.transaction.gateway_rejection_reason]
    end
  end

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
