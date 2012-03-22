require File.expand_path('../../test_helper', __FILE__)

class PaymentMethodApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
    ::Authorizer.send(:extend, TestAuthorizer)
  end

  def test_create_payment_method_without_id_and_with_token
    post("/payment_methods", {:card_token => "abc123"})
    assert_equal(201, last_response.status)
    body = JSON.parse(last_response.body)
    refute_nil body["id"]
    assert_equal("abc123", body["card_token"])
  end

  def test_create_payment_method_with_id_and_with_token
    put("/payment_methods/9999", {:card_token => "abc123"})
    assert_equal(201, last_response.status)
    body = JSON.parse(last_response.body)
    assert_equal("9999", body["id"])
    assert_equal("abc123", body["card_token"])
  end

  def test_create_payment_method_with_id_and_without_token_good_card
    put("/payment_methods/9999", {
      :card_num => TestAuthorizer::GOOD_NUM,
      :card_exp_year => "2011",
      :card_exp_month => "01"
    })
    assert_equal(201, last_response.status)
    body = JSON.parse(last_response.body)
    assert_equal("9999", body["id"])
    assert_equal(TestAuthorizer::TOKEN, body["card_token"])
  end

  def test_create_payment_method_with_id_and_without_token_bad_card
    put("/payment_methods/9999", {
      :card_num => TestAuthorizer::BAD_NUM,
      :card_exp_year => "2011",
      :card_exp_month => "01"
    })
    assert_equal(422, last_response.status)
  end

end
