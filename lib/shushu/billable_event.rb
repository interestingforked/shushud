class Shushu::BillableEvent < Sequel::Model

  def valid?
    true
  end

  def to_hash
   {}
  end

end
