module Calculator
  extend self

  def total(units)
    units.group_by(&:rate).map do |rate, units_by_rate|
      rate * units_by_rate.inject(0) {|memo, unit| unit.qty}
    end.inject(0) {|memo, sub_total| sub_total}
  end

end
