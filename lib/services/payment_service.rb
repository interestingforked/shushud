module PaymentService
  extend self

  PREPARE = "prepare"
  SUCCESS = "success"

  def attempt(recid, pmid, wait_until)
    [201, create_record(PREPARE, recid, pmid, wait_until).to_h]
  end

  def ready_process
    Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * FROM payments_ready_for_process").to_a
    end
  end

  private

  def create_record(state, recid, pmid, wait_until)
    PaymentAttemptRecord.create(
      :payment_method_id => pmid,
      :receivable_id => recid,
      :wait_until => wait_until,
      :state => state
    )
  end

end
