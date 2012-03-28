require "sequel/extensions/pg_array"
require "sequel/extensions/pg_hstore"

module ReportService
  extend self

  def rate_code_report(rc_slug, from, to)
    Log.info_t(
      :action    => "rate_code_report",
      :rate_code => rc_slug,
      :from      => from,
      :to        => to
    ) do
      rcid = RateCode.resolve_id(rc_slug)
      s = "SELECT * FROM rate_code_report($1, $2, $3)"
      billable_units = exec_sql(s, rcid, from, to)
      [200, {
        :rate_code      => rc_slug,
        :from           => from,
        :to             => to,
        :billable_units => billable_units,
        :total          => Calculator.total(billable_units)
      }]
    end
  end

  def usage_report(account_id, from, to)
    Log.info_t(
      :action     => "usage_report",
      :account_id => account_id,
      :from       => from,
      :to         => to
    ) do
      s = "SELECT * FROM usage_report($1, $2, $3)"
      billable_units = exec_sql(s, account_id, from, to)
      [200, {
        :account_id     => account_id,
        :from           => from,
        :to             => to,
        :billable_units => billable_units,
        :total          => Calculator.total(billable_units)
      }]
    end
  end

  def invoice(payment_method_id, from, to)
    Log.info_t(
        :action         => "usage_report",
        :payment_method => payment_method_id,
        :from           => from,
        :to             => to
      ) do
      s = "SELECT * FROM invoice($1, $2, $3)"
      s << " WHERE payment_method_id = $4"
      billable_units = {}
      invoice = exec_sql(s, from, to, 0, payment_method_id).each do |li|
        billable_units[li["hid"]] = p_a(li["billable_units"]).map {|h| p_h(h)}
      end
      [200, {
        :payment_method_id => payment_method_id,
        :from              => from,
        :to                => to,
        :billable_units    => billable_units,
        :total             => invoice.map {|x| x["total"].to_f}.reduce(:+)
      }]
    end
  end

  def rev_report(from, to, credit=0)
    Log.info_t(:action => "rev_report", :from => from, :to => to) do
      s = "SELECT rev_report($1, $2, $3)"
      total = exec_sql(s, from, to, credit).pop["rev_report"].to_f
      [200, {:time => Time.now, :total => total}]
    end
  end

  def res_diff(lfrom, lto, rfrom, rto, sbit)
    Log.info_t(:action => "res_diff", :sbit => sbit) do
      s = "SELECT * FROM res_diff($1, $2, $3, $4, $5)"
      resources = exec_sql(s, lfrom, lto, rfrom, rto, sbit)
      [200, {:resources => resources}]
    end
  end

  def exec_sql(sql, *args)
    Shushu::DB.synchronize do |conn|
      conn.exec(sql, args).to_a
    end
  end

  def p_a(str)
    Sequel::Postgres::PGArray.parse(str)
  end

  def p_h(str)
    Sequel::Postgres::HStore.parse(str)
  end

end
