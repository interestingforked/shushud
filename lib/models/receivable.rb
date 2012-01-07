class Receivable < Sequel::Model

  def self.find_prev(pmid, from, to)
    prevs = filter(:init_payment_method_id => pmid, :period_start => from, :period_end => to).all
    if prevs.length == 0
      nil
    elsif prevs.length == 1
      prevs.pop
    else
      raise(ShushuError, "Found #{prevs.length} receivables with payment_method=#{pmid} AND from=#{from} AND to=#{to}")
    end
  end

  def to_h
    {
      :id => self[:id]
    }
  end

end
