class Shushu::BillableEvent < Sequel::Model

  ILLEGAL_CHANGE = "illegal change"

  ATTRS = [:provider_id, :resource_id, :event_id, :reality_from, :reality_to, :qty, :rate_code]

  def self.find_or_instantiate_by_provider_and_event(provider_id, event_id)
    params = {:provider_id => provider_id, :event_id => event_id}
    filter(params).first or new(params)
  end

  def api_values
    {
      :provider_id => self[:provider_id],
      :event_id    => self[:event_id],
      :resource_id => self[:resource_id],
      :rate_code   => self[:rate_code],
      :qty         => self[:qty],
      :from        => self[:reality_from],
      :to          => self[:reality_to]
    }
  end

  def public_values
    values.select {|k,v| ATTRS.include?(k) }
  end

  def validate
    super

    if !new?
      detect_incorrect_data_change
    end
  end

  def detect_incorrect_data_change
    if !only_modifying_reality_to?
      changed_from_non_nil_columns.each {|col| errors.add(col, ILLEGAL_CHANGE) }
    end
  end

  def only_modifying_reality_to?
    if modified?
      changed_columns == [:reality_to]
    else
      true
    end
  end

  # Say that reality_to is nil in the database and qty is not nil. Also say that
  # we have set both qty and reality_to to some non-nil value.
  # This method will tell us that qty is the only changed column.
  def changed_from_non_nil_columns
    changed_columns.reject {|col| self.class[self.id][col].nil? }
  end

end
