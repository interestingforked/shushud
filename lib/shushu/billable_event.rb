class Shushu::BillableEvent < Sequel::Model

  ATTRS = [:provider_id, :resource_id, :event_id, :reality_from, :reality_to, :qty, :rate_code]

  def similar?(hash)
    tmp_self = values.dup

    tmp_self.delete(:id)
    tmp_self.delete(:system_from)
    tmp_self.delete(:system_to)

    tmp_self.all? {|k,v| hash[k].to_s == v.to_s}
  end

  def validate
    super
  end

  def valid?
    true
  end

  def to_hash
   {}
  end

end
