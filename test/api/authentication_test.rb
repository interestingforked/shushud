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

    def set_provider_id
      true
    end

    def session
      {}
    end
  end

  def setup
    super
    @auth = TestAuth.new
    @auth.send(:extend, Api::Authentication)

    @provider = build_provider(:token => "abc123")
  end

  def test_authenticate_sets_params
    @auth.pass?(@provider.id, "abc123")
    assert_equal @provider.id, @auth.params[:provider_id]
  end

  def test_authenticate_sets_request_env
    @auth.pass?(@provider.id, "abc123")
    assert_equal @provider.id, @auth.request.env["PROVIDER_ID"]
  end

  def test_authenticate_returns_false_when_not_valid_provider_token
    assert ! @auth.pass?(@provider.id, (@provider.token + "bad"))
  end

  def test_authenticate_returns_false_when_not_valid_provider_id
    assert ! @auth.pass?(99999, "abc123")
  end

  def test_authenticate_returns_true_when_valid_provider_id_and_token
    assert @auth.pass?(@provider.id, "abc123")
  end

end
