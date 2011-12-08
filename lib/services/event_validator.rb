class EventValidator
  # Responsibility: Determine the validity of an event.

  # This class relies on an event having the following methods defined:
  # -> Event#from
  # -> Event#qty
  # -> Event#rate_code
  # -> Event#provider_id

  def self.invalid?(existing_event, proposed_changes)
    validator = new(existing_event, proposed_changes)
    validator.invalid?
  end

  def initialize(existing_event, proposed_changes)
    @proposed_changes = proposed_changes
    @existing_event = existing_event
  end

  def invalid?
    [rate_code_mismatch?, illegal_change?].any?
  end

  def illegal_change?
    [difference_in_reality_from?, difference_in_qty?].any?
  end

  def difference_in_reality_from?
    if r_from = @proposed_changes[:reality_from]
      if @existing_event.reality_from.to_s != r_from.to_s
        log("difference in reality_from")
        true
      else
        false
      end
    else
      false
    end
  end

  def difference_in_qty?
    if qty = @proposed_changes[:qty]
      if @existing_event.qty.to_i != qty.to_i
        log("difference in qty")
        true
      else
        false
      end
    else
      false
    end
  end

  def rate_code_mismatch?
    rate_code = find_rate_code(@proposed_changes[:rate_code], @proposed_changes[:provider_id])
    if @proposed_changes[:rate_code]
      if @existing_event.rate_code_id != rate_code.id
        log("rate_code_mismatch existing_rate_code=#{@existing_event[:rate_code_id]} proposed_rate_code=#{rate_code.id}")
        true
      else
        false
      end
    else
      false
    end
  end

  def find_rate_code(slug, provider_id)
    RateCode.filter(:slug => slug, :provider_id => provider_id).first
  end

  def log(msg)
    shulog(msg)
  end
end
