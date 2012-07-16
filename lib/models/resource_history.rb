module ResourceHistory
  extend self

  def fetch(owner, from, to)
    [200,
      resource_histories(owner, from, to)]
  end

  def resource_histories(owner, from, to)
    fold_res_own(owner, from, to).map do |r|
      {resource_id: r[:resource_id],
        billable_events: fold_events(r[:resource_id], r[:from], r[:to])}
    end
  end

  def fold_events(resid, from, to)
    b_events(resid).map do |bc|
      open = bc.find {|b| b[:state] == 1}
      closed = bc.find {|b| b[:state] == 0}
      next if open.nil? # TODO remove events that are closed and not open
      f = [open[:time], from].max
      t = [((closed && closed[:time]) || Time.now), to].min
      {resource_id: open[:hid],
        from: f,
        to: t,
        qty: qty(f, t),
        product_group: open[:product_group],
        product_name: open[:product_name],
        description: open[:description],
        rate: open[:rate],
        rate_period: open[:rate_period]}
    end
  end

  def b_events(resid)
    sql = <<EOD
   select entity_id_uuid, hid, time, product_group, description, rate, rate_period, coalesce(billable_events.product_name, rate_codes.product_name) as product_name
      from billable_events, rate_codes
      where billable_events.rate_code_id = rate_codes.id
      and billable_events.provider_id = 5
      and hid = $1
EOD
    Utils.exec(sql, resid).group_by {|b| b[:entity_id_uuid]}
  end

  def fold_res_own(owner, from, to)
    res_records(owner).map do |rc|
      open = rc.find {|r| r[:state] == 1}
      closed = rc.find {|r| r[:state] == 0}
      f = [open[:time], from].max
      t = [((closed && closed[:time]) || Time.now), to].min
      {resource_id: open[:hid],
        owner: open[:owner],
        from: f,
        to: t}
    end
  end

  def res_records(owner)
    ResourceOwnershipRecord.
      filter(owner: owner).
      to_a.
      group_by {|r| r[:entity_id]}.
      values
  end

  def qty(f, t)
    (t - f) / 3600
  end
end
