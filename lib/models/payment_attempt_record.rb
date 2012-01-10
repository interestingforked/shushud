class PaymentAttemptRecord < Sequel::Model
  def to_h
    {
      :id => self[:id],
      :wait_until => self[:wait_until]
    }
  end
end
