module BillableUnitBuilder
  extend self

  def build(account_id, from, to)
    Shushu::DB.fetch(<<-EOD, from, to, account_id).all.map {|item| build_billable_units(item)}
      SELECT
        resource_ownerships.account_id,
        billable_units.hid,
        GREATEST(billable_units.from, resource_ownerships.from, '#{from}') as from_timestamp,
        LEAST(billable_units.to, resource_ownerships.to, '#{to}') as to_timestamp,
        (
          (extract('epoch' FROM
            LEAST(billable_units.to, resource_ownerships.to, '#{to}') - GREATEST(billable_units.from, resource_ownerships.from, '#{from}')
          ) / (3600)) -- convert seconds into hours
        ) as qty,
        rate_codes.product_name,
        rate_codes.product_group,
        rate_codes.rate,
        rate_codes.rate_period

        FROM billable_units
        LEFT OUTER JOIN rate_codes
          ON
            rate_codes.id = billable_units.rate_code_id
        INNER JOIN resource_ownerships
          ON
            billable_units.hid = resource_ownerships.hid
        WHERE
          resource_ownerships.account_id = #{account_id}
          AND
            (billable_units.from, billable_units.to)
            OVERLAPS
            (resource_ownerships.from, resource_ownerships.to)
      ;
    EOD
  end

  def build_billable_units(item)
    BillableUnit.new do |bu|
      bu.account_id     = item[:account_id]
      bu.hid            = item[:hid]
      bu.from           = item[:from_timestamp]
      bu.to             = item[:to_timestamp]
      bu.rate           = item[:rate]
      bu.rate_period    = item[:rate_period]
      bu.product_group  = item[:product_group]
      bu.product_name   = item[:product_name]
      bu.qty            = item[:qty]
    end
  end

end
