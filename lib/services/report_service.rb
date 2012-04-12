require "sequel/extensions/pg_array"
require "sequel/extensions/pg_hstore"

module ReportService
  extend self

  def rate_code_report(rc_slug, from, to)
    rcid = RateCode.resolve_id(rc_slug)
    s = "SELECT * FROM rate_code_report($1, $2, $3)"
    billable_units = Utils.read_exec(s, rcid, from, to)
    [200, {
      :rate_code      => rc_slug,
      :from           => from,
      :to             => to,
      :billable_units => billable_units,
      :total          => Calculator.total(billable_units)
    }]
  end

  def usage_report(account_id, from, to)
    s = "SELECT * FROM usage_report($1, $2, $3)"
    billable_units = Utils.read_exec(s, account_id, from, to)
    [200, {
      :account_id     => account_id,
      :from           => from,
      :to             => to,
      :billable_units => billable_units,
      :total          => Calculator.total(billable_units)
    }]
  end

  def invoice(payment_method_id, from, to)
    s = "SELECT * FROM invoice($1, $2, $3)"
    s << " WHERE payment_method_id = $4"
    billable_units = {}
    invoice = Utils.read_exec(s, from, to, 0, payment_method_id).each do |li|
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

  def rev_report(from, to, credit=0)
    s = "SELECT rev_report($1, $2, $3)"
    total = Utils.read_exec(s, from, to, credit).pop["rev_report"].to_f
    [200, {:time => Time.now, :total => total}]
  end

  def res_diff(lfrom, lto, rfrom, rto, delta_increase, lrev_zero, rrev_zero, limit=100)
    s = "SELECT * FROM res_diff($1, $2, $3, $4, $5, $6, $7) LIMIT $8"
    resources = Utils.read_exec(s, lfrom, lto, rfrom, rto, delta_increase, lrev_zero, rrev_zero, limit)
    [200, {:resources => resources}]
  end

  def res_diff_agg(lfrom, lto, rfrom, rto, delta_increase, lrev_zero, rrev_zero)
    s = "SELECT * FROM res_diff_agg($1, $2, $3, $4, $5, $6, $7)"
    r = Utils.read_exec(s, lfrom, lto, rfrom, rto, delta_increase, lrev_zero, rrev_zero).pop
    [200, {:diff => r['sdiff'], :ltotal => r['sltotal'], :rtotal => r['srtotal']}]
  end

  def p_a(str)
    Sequel::Postgres::PGArray.parse(str)
  end

  def p_h(str)
    Sequel::Postgres::HStore.parse(str)
  end

end
