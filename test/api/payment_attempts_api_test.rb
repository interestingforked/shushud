require File.expand_path('../../test_helper', __FILE__)

class PaymentAttemptsApiTest < ShushuTest

  def setup_auth
    authorize('core', ENV["VAULT_PASSWORD"])
  end

  def test_create_attempt
    setup_auth
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    post("/receivables/#{receivable.id}/payment_attempts", {:payment_method_id => payment_method.id,})
    assert_equal(201, last_response.status)
    refute_nil JSON.parse(last_response.body)["id"]
  end

end
