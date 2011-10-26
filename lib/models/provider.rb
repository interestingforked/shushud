class Provider < Sequel::Model
  
  def root?
    self[:root]
  end
  
  def write_to_billable_events?
    self[:billable_events] == true
  end
  
end
