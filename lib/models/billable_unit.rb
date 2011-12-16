class BillableUnit

  attr_accessor(
    :hid,
    :account_id,
    :from,
    :to
  )

  def initialize
    yield self
  end

  def to_h
    {
      :hid        => hid,
      :account_id => account_id,
      :from       => from,
      :to         => to
    }
  end

end
