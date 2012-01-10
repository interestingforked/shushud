require File.expand_path('../../test_helper', __FILE__)

class PaymentServiceTest < ShushuTest
  def setup
    super
    Shushu::Conf[:gateway] = TestGateway
  end

  def test_find_ready_process
    assert_equal(0, PaymentService.ready_process.length)
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    build_attempt(PaymentService::PREPARE, receivable.id, payment_method.id, nil, nil)
    assert_equal(1, PaymentService.ready_process.length)
  end

  def test_find_ready_process_excludes_success
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    build_attempt(PaymentService::PREPARE, receivable.id, payment_method.id, nil, nil)
    assert_equal(1, PaymentService.ready_process.length)
    build_attempt(PaymentService::SUCCESS, receivable.id, payment_method.id, nil, nil)
    assert_equal(0, PaymentService.ready_process.length)
  end

  def test_process_approved_charge
    TestGateway.force_success = true
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    res = PaymentService.process(receivable.id, payment_method.id)
    assert_equal(201, res.first)
    payment_attempt = res.last
    assert_equal(PaymentService::SUCCESS, payment_attempt[:state])
  end

  def test_process_declined_charge
    TestGateway.force_success = false
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    res = PaymentService.process(receivable.id, payment_method.id)
    assert_equal(422, res.first)
    payment_attempt = res.last
    assert_equal(PaymentService::FAILED, payment_attempt[:state])
  end

end
