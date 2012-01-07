require File.expand_path('../../test_helper', __FILE__)

class ReceivablesApiTest < ShushuTest

  def setup_auth
    authorize('core', ENV["VAULT_PASSWORD"])
  end

  def test_create_account
    setup_auth
    payment_method = build_payment_method
    post("/receivables", {
      :init_payment_method_id => payment_method.id,
      :amount => 1000,
      :from => Time.utc(2011,1),
      :to => Time.utc(2011,2)
    })
    assert_equal(201, last_response.status)
    refute_nil JSON.parse(last_response.body)["id"]
  end

end
