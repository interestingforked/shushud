class Provider < Sequel::Model
  
  def root?
    self[:root]
  end
  
end
