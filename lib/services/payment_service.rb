module PaymentService
  extend self

  PREPARE = "prepare"
  SUCCESS = "success"
  FAILED  = "failed"

  def attempt(recid, pmid, wait_until)
    [201, create_record(PREPARE, recid, pmid, wait_until, nil).to_h]
  end

  def process(recid, pmid)
    rec = resolve_rec(recid)
    pm  = resolve_pm(pmid)
    res = gateway.charge(pm.card_token, rec.amount, rec.id)
    if res[:success]
      [201, create_record(SUCCESS, recid, pmid, nil, res[:text]).to_h]
    else
      #TODO This is where we can handle retry logic.
      [422, create_record(FAILED, recid, pmid, nil, res[:text]).to_h]
    end
  end

  # Return a collection of [receivable_id, payment_method_id]
  # that are marked as prepare but have no corresponding attempts marked as
  # success.
  def ready_process
    Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * FROM payments_ready_for_process").to_a
    end
  end

  private

  # We need a module that will respond to charge(token, amount, receivable_id)
  def gateway
    Shushu::Conf[:gateway]
  end

  def create_record(state, recid, pmid, wait_until, desc)
    PaymentAttemptRecord.create(
      :payment_method_id => pmid,
      :receivable_id => recid,
      :wait_until => wait_until,
      :state => state,
      :desc => desc
    )
  end

  def resolve_rec(id)
    if rec = Receivable[id]
      rec
    else
      raise(Shushu::NotFound, "unable_find_receivable receivable=#{id}")
    end
  end

  def resolve_pm(id)
    if pm = PaymentMethod[id]
      pm
    else
      raise(Shushu::NotFound, "unable_find_payment_method payment_method=#{id}")
    end
  end

end
