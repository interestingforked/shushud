class Response

  attr_accessor(
    :existing_record,
    :data
  )

  def initialize
    yield self if block_given?
  end

  def new_record_created?
    !existing_record?
  end

  def existing_record?
    @existing_record
  end

end
