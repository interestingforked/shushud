class ResourceOwnershipRecord < Sequel::Model
  ACTIVE = 1
  INACTIVE = 0

  def to_h
    {
      :owner       => self[:owner],
      :resource_id => self[:hid],
      :from        => self[:from],
      :to          => self[:to]
    }
  end

end
