class BillableUnit

  attr_accessor(
    :hid,
    :account_id,
    :from,
    :to,
    :rate,
    :rate_period,
    :qty,
    :total,
    :product_group,
    :product_name
  )

  def initialize
    yield self
  end

  def to_h
    {
      :hid           => hid,
      :account_id    => account_id,
      :from          => from,
      :to            => to,
      :rate          => rate,
      :rate_period   => rate_period,
      :qty           => qty,
      :total         => total,
      :product_name  => product_name,
      :product_group => product_group
    }
  end

end
