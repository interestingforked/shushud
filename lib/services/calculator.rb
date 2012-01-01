module Calculator
  extend self

  def total(units)
    units.group_by {|unit| unit["rate"].to_i}.map do |rate, units_by_rate|
      sum_of_qty = units_by_rate.map {|u| u["qty"].to_f}.reduce(:+)
      rate * sum_of_qty
    end.reduce(:+)
  end

end
