class Sequel::Model

  def before_create
    if self.class.columns.include?(:created_at)
      self[:created_at] ||= Time.now
    end
  end

end
