module PaymentService
  extend self

  PREPARE       = "prepare"
  SUCCESS       = "success"
  FAILED_ACT    = "failed_action"
  FAILED_NOACT  = "failed_no_action"
  STATEMAP      = {
    SUCCESS      => 201,
    FAILED_ACT   => 422,
    FAILED_NOACT => 422
  }
  TRANSITION_CALLBACK = {}

  def attempt(recid, pmid, wait_until)
    [201, create_record(PREPARE, recid, pmid, wait_until, nil).to_h]
  end

  def process(recid, pmid, skip_retry=false)
    rec, pm = resolve_rec(recid), resolve_pm(pmid)
    state, resp = gateway.charge(pm.card_token, rec.amount, rec.id)
    handle_transition!(state, skip_retry)
    [determine_status(state), create_record(state, recid, pmid, nil, resp).to_h]
  end

  # Return a collection of [receivable_id, payment_method_id]
  # that are marked as prepare but have no corresponding attempts marked as
  # success.
  def ready_process
    Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * FROM payments_ready_for_process").to_a
    end
  end

  # There is a file in this project's ./etc dir that should define what happens
  # of transitions. The motivation for this approach is that our strategy for changing how
  # we handle failed payments will change often. Thus it should be simple and
  # easy to define new strategies.
  def setup_transitions
    t = OpenStruct.new
    def t.to(state, &blk)
      TRANSITION_CALLBACK[state.to_s] = blk
    end
    yield t
    TRANSITION_CALLBACK
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
    Receivable[id] || raise(Shushu::NotFound, "unable_find_receivable receivable=#{id}")
  end

  def resolve_pm(id)
    PaymentMethod[id] || raise(Shushu::NotFound, "unable_find_payment_method payment_method=#{id}")
  end

  def determine_status(state)
    assert_can_handle_state!(state)
    STATEMAP[state]
  end

  # See: #setup_transitions
  # This method will call code defined in a configuration like file. Callers of
  # this method should assume the worst. There is nothing stopping this method
  # from taking 4000ms to return.
  #
  # We also make use of our ability to bind variables to blocks. Each transition
  # definition defined in the conf file should can use the block's bind vars to
  # vary the strategy at runtime.
  def handle_transition!(state, skip_retry)
    assert_can_handle_state!(state)
    if blk = TRANSITION_CALLBACK[state]
      blk.call({:skip_retry => skip_retry})
    end
  end

  def assert_can_handle_state!(state)
    STATEMAP.keys.include?(state) || raise(Shushu::ShushuError, "Payments can not handle state=#{state}")
  end

end
