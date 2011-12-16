module BillableUnitBuilder
  extend self

  def build(account_id, from, to)
    Shushu::DB.fetch(<<-EOD, from, to, account_id).all.map {|item| build_billable_units(item)}
      SELECT
        resource_ownerships.account_id,
        billable_units.hid,
        GREATEST(billable_units.from, resource_ownerships.from, ?) as from,
        LEAST(billable_units.to, resource_ownerships.to, ?) as to
        FROM billable_units
        INNER JOIN resource_ownerships
          ON
            billable_units.hid = resource_ownerships.hid
        WHERE
          resource_ownerships.account_id = ?
      ;
    EOD
  end

  def build_billable_units(item)
    BillableUnit.new do |bu|
      bu.account_id = item[:account_id]
      bu.hid = item[:hid]
      bu.from = item[:from]
      bu.to = item[:to]
    end
  end

end
