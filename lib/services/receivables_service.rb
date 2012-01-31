module ReceivablesService
  extend self

  def collected?(recid)
    PaymentAttemptRecord.filter(
      :state => PaymentService::SUCCESS,
      :receivable_id => recid
    ).count > 0
  end

  def create(provider_id, pmid, amount, from, to)
    if prev = Receivable.find_prev(pmid, from, to)
      [200, prev.to_h]
    else
      [201, create_record(provider_id, pmid, amount, from, to).to_h]
    end
  end

  def create_record(provider_id, pmid, amount, from, to)
    Receivable.create(
      :provider_id            => provider_id,
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
