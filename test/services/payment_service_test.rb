require File.expand_path('../../test_helper', __FILE__)

class PaymentServiceTest < ShushuTest

  def setup
    super
    Shushu::Conf[:gateway] = TestGateway

    @failed_no_action_flag = false
    @success_flag = false
    PaymentService.setup_transitions do |transition|
      transition.to(:failed_no_action) do |opts|
        @failed_no_action_flag = true
      end
      transition.to(:success) do |opts|
        @success_flag = true
      end
    end
  end

  def test_find_ready_process
    assert_equal(0, PaymentService.ready_process.length)
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    build_attempt(PaymentService::PREPARE, provider.id, receivable.id, payment_method.id, nil, nil)
    assert_equal(1, PaymentService.ready_process.length)
  end

  def test_find_ready_process_excludes_success
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    build_attempt(PaymentService::PREPARE, provider.id, receivable.id, payment_method.id, nil, nil)
    assert_equal(1, PaymentService.ready_process.length)
    build_attempt(PaymentService::SUCCESS, provider.id, receivable.id, payment_method.id, nil, nil)
    assert_equal(0, PaymentService.ready_process.length)
  end

  def test_find_ready_process_excludes_premature
    assert_equal(0, PaymentService.ready_process.length)
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    build_attempt(PaymentService::PREPARE, provider.id, receivable.id, payment_method.id, (Time.utc(Time.now.year + 1)), nil)
    assert_equal(0, PaymentService.ready_process.length)
  end

  def test_find_ready_process_excludes_duplicate_receivables
    assert_equal(0, PaymentService.ready_process.length)
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    build_attempt(PaymentService::PREPARE, provider.id, receivable.id, payment_method.id, nil, nil)
    build_attempt(PaymentService::PREPARE, provider.id, receivable.id, payment_method.id, nil, nil)
    assert_equal(1, PaymentService.ready_process.length)
  end

  def test_process_approved_charge
    TestGateway.force_success = true
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    res = PaymentService.process(provider.id, receivable.id, payment_method.id)
    assert_equal(201, res.first)
    payment_attempt = res.last
    assert_equal(PaymentService::SUCCESS, payment_attempt[:state])
    assert(@success_flag, "The state transition block was not called.")
  end

  def test_process_declined_charge
    TestGateway.force_success = false
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    res = PaymentService.process(provider.id, receivable.id, payment_method.id)
    assert_equal(422, res.first)
    payment_attempt = res.last
    assert_equal(PaymentService::FAILED_NOACT, payment_attempt[:state])
    assert(@failed_no_action_flag, "The state transition block was not called.")
  end

  def provider
    @provider ||= build_provider
  end

end
