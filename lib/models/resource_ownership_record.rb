class ResourceOwnershipRecord < Sequel::Model

  Active = "active"
  Inactive = "inactive"

  def self.find(account_id, from, to)
    self.dataset.with_sql(<<-EOD, account_id)
      SELECT a.account_id, a.hid, a.time as from, COALESCE(b.time, now()) as to
        FROM resource_ownership_records a
        LEFT OUTER JOIN resource_ownership_records b
        ON a.account_id = b.account_id AND a.state = '#{Active}' AND b.state = '#{Inactive}'
        WHERE a.state = '#{Active}'
        AND a.account_id = ?
    EOD
  end

end
