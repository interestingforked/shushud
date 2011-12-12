require File.expand_path('../../test_helper', __FILE__)

class AuthenticationTest < ShushuTest

  class TestAuth
    attr_reader :params, :env
    def initialize
      @params = {}
      @env = {}
    end

    def request
      def env
        @env
      end
      self
    end
  end

  def setup
    super
    @auth = TestAuth.new
    @auth.send(:extend, Http::Authentication)

    @provider = Provider.create(:token => "abc123")
  end

  def test_authenticate_sets_params
    @auth.authenticate(@provider.id, @provider.token)
    assert_equal @provider.id, @auth.params[:provider_id]
  end

  def test_authenticate_sets_request_env
    @auth.authenticate(@provider.id, @provider.token)
    assert_equal @provider.id, @auth.request.env["PROVIDER_ID"]
  end

  def test_authenticate_returns_false_when_not_valid_provider_token
    assert ! @auth.authenticate(@provider.id, (@provider.token + "bad"))
  end

  def test_authenticate_returns_false_when_not_valid_provider_id
    assert ! @auth.authenticate(99999, @provider.token)
  end

  def test_authenticate_returns_true_when_valid_provider_id_and_token
    assert @auth.authenticate(@provider.id, @provider.token)
  end

end
