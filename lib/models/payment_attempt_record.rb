class PaymentAttemptRecord < Sequel::Model
  def to_h
    {:id => self[:id]}
  end
end
