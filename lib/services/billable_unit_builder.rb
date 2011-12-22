module BillableUnitBuilder
  extend self

  def build(account_id, from, to)
    shulog("#billable_unit_builder_select account=#{account_id} from=#{from} to=#{to}")
    Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * FROM usage_report($1, $2, $3)", [account_id, from, to])
    end
  end
end
