module Utils
  extend self

  UUID4_REGEX = /^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/

  def validate_uuid(str)
    str =~ UUID4_REGEX ? str : nil
  end

  def validate_uuid!(str)
    if str =~ UUID4_REGEX
      str
    else
      raise(ArgumentError, "expected #{str} to be UUIDv4")
    end
  end

end
