module Calculator
  extend self

  def total(units)
    units.group_by {|unit| unit["rate"].to_i}.map do |rate, units_by_rate|
      rate * units_by_rate.inject(0) {|memo, unit| unit["qty"].to_f}
    end.inject(0) {|memo, sub_total| sub_total}
  end

end
