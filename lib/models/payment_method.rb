class PaymentMethod < Sequel::Model

  def card_token
    CardToken.
    filter(:payment_method_id => self[:id]).
    order(:created_at).
    first
  end

  def api_id
    self[:slug] || self[:id]
  end

end
