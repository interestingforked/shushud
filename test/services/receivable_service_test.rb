require File.expand_path('../../test_helper', __FILE__)

class ReceivablesServiceTest < ShushuTest

  def test_collected
    pm = build_payment_method
    rec = build_receivable(pm.id, 100, nil, nil)
    refute ReceivablesService.collected?(rec.id)
    build_attempt(PaymentService::SUCCESS, rec.id, pm.id, nil, nil)
    assert ReceivablesService.collected?(rec.id)
  end

end

