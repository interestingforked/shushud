module PaymentService
  extend self

  def attempt(recid, pmid)
  [201, create_record(recid, pmid).to_h]
  end

  def create_record(recid, pmid)
    PaymentAttemptRecord.create(
      :payment_method_id => pmid,
      :receivable_id => recid
    )
  end

end
