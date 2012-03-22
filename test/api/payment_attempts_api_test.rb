require File.expand_path('../../test_helper', __FILE__)

class PaymentAttemptsApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
  end

  def setup_auth
    authorize(@provider.id, "abc123")
  end

  def test_create_attempt
    setup_auth
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    post("/receivables/#{receivable.id}/payment_attempts", {:payment_method_id => payment_method.id})
    assert_equal(201, last_response.status)
    refute_nil JSON.parse(last_response.body)["id"]
  end

  def test_create_attempt_for_later_time
    setup_auth
    payment_method = build_payment_method
    receivable = build_receivable(payment_method.id, 1000, jan, feb)
    post("/receivables/#{receivable.id}/payment_attempts", {
      :payment_method_id => payment_method.id,
      :wait_until => feb.utc
    })
    assert_equal(201, last_response.status)
    res = JSON.parse(last_response.body)
    refute_nil(res["id"])
    assert_equal(feb.utc.to_s, res["wait_until"])
  end

end
