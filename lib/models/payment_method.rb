class PaymentMethod < Sequel::Model

  def card_token
    #TODO should consider race condition when 2 Shushus
    # write a card_token at the exact same time.
    CardToken.
    filter(:payment_method_id => self[:id]).
    order(:created_at).
    first
  end

  def api_id
    self[:slug] || self[:id]
  end

end
