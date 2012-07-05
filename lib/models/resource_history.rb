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
      f = [open[:time], from].max
      t = [closed[:time], to].min
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
    BillableEvent.
      filter(resource_id: resid).
      join(:rate_codes, :id => :rate_code_id).
      to_a.
      group_by {|b| b["entity_id_uuid"]}.
      values
  end

  def fold_res_own(owner, from, to)
    res_records(owner).map do |rc|
      open = rc.find {|r| r[:state] == 1}
      closed = rc.find {|r| r[:state] == 0}
      {resource_id: open[:resource_id],
        owner: open[:owner],
        from: [open[:time], from].max,
        to: [closed[:time], to].min}
    end
  end

  def res_records(owner)
    ResourceOwnershipRecord.
      filter(owner: owner).
      to_a.
      group_by {|r| r["entity_id"]}.
      values
  end

  def qty(f, t)
    (t - f) / 3600
  end
end
