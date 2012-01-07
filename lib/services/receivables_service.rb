module ReceivablesService
  extend self

  def create(pmid, amount, from, to)
    if prev = Receivable.find_prev(pmid, from, to)
      [200, prev.to_h]
    else
      [201, create_record(pmid, amount, from, to).to_h]
    end
  end

  def create_record(pmid, amount, from, to)
    Receivable.create(
        :init_payment_method_id => resolve_pmid(pmid),
        :amount                 => amount,
        :period_start           => from,
        :period_end             => to
      )
  end

  def resolve_pmid(i)
    if pm = PaymentMethod[i]
      pm[:id]
    else
      raise(Shushu::NotFound, "Could not find payment_method with init_payment_method=#{i}")
    end
  end
end
