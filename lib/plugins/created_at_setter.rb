module CreatedAtSetter

  def set_created_at
    if self.class.columns.include?(:created_at)
      self[:created_at] ||= Time.now
    end
  end

end
