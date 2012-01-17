require File.expand_path('../../test_helper', __FILE__)

class ProviderTest < ShushuTest

  def test_auth
    provider = build_provider
    provider.reset_token!('123')
    assert(Provider.auth?(provider.id, '123'), "Expected a successful auth")
  end

  def test_auth_when_disabled
    provider = build_provider(:disabled => true)
    provider.reset_token!('123')
    refute(Provider.auth?(provider.id, '123'), "Expected a failed auth")
  end

end
