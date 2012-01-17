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
      shulog("#unauthenticated credentials=#{auth.credentials.join("/")} ip=#{request.env["REMOTE_ADDR"]} agent=#{request.env["HTTP_USER_AGENT"]}")
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, enc_json("Not authorized")])
    end

    def authenticate_provider
      if authenticated?
        shulog("#session_found provider=#{session[:provider_id]}")
      else
        if auth.provided? && auth.basic?
          id, token = *auth.credentials
          shulog("#session_begin provider=#{id}")
          pass?(id, token) || unauthenticated!
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
