module Api
  module Authentication
    include Helpers

    def auth
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
    end

    def bad_request!
      throw(:halt, [400, enc_json("Bad Request")])
    end

    def unauthenticated!(realm="shushu.heroku.com")
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, enc_json("Not authorized")])
    end

    def authenticated?
      request.env["PROVIDER_ID"] || session[:provider_id]
    end

    def core?(user, password)
      user == 'core' && password == ENV["VAULT_PASSWORD"]
    end

    def authenticate_provider
      return if authenticated?
      if auth.provided? && auth.basic?
        pass?(*auth.credentials) || unauthenticated!
      elsif (params[:provider_id] && params[:provider_token])
        pass?(params[:provider_id], params[:provider_token]) || unauthenticated!
      else
        bad_request!
      end
    end

    def pass?(id, token)
      id = id.to_i
      if Provider.auth?(id, token)
        set_provider_id(id.to_i)
        true
      else
        false
      end
    end

    def set_provider_id(i)
      session[:provider_id] = i
      request.env["PROVIDER_ID"] = i
      params[:provider_id] = i
    end

    def authenticate_trusted_consumer
      unauthenticated!  unless auth.provided?
      bad_request!      unless auth.basic?
      unauthenticated!  unless core?(*auth.credentials)
    end

  end
end
