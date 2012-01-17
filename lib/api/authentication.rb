module Api
  module Authentication
    include Helpers
    include Sinatra::Cookies

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

    def authenticate_provider
      if authenticated?
        shulog("#session_found provider=#{params[:provider_id]}")
      else
        shulog("#session_begin provider=#{params[:provider_id]}")
        if auth.provided? && auth.basic?
          pass?(*auth.credentials) || unauthenticated!
        elsif (params[:provider_id] && params[:provider_token])
          pass?(params[:provider_id], params[:provider_token]) || unauthenticated!
        else
          bad_request!
        end
      end
    end

    def authenticated?
      session[:provider_id]
    end

    def pass?(id, token)
      id = id.to_i
      if Provider.auth?(id, token)
        session[:provider_id] = id
      else
        false
      end
    end

  end
end
