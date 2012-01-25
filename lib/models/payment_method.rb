class PaymentMethod < Sequel::Model

  def card_token
    CardToken.
    filter(:payment_method_id => self[:id]).
    order(:created_at).
    first
  end

end
