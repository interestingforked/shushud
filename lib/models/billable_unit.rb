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

end
