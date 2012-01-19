module Api
  module Authentication
    include Helpers
    include Sinatra::Cookies

    def authenticate_provider
      if authenticated?
        Log.info("#session_found provider=#{session[:provider_id]}")
      else
        if proper_request?
          id, token = *auth.credentials
          Log.info("#session_begin provider=#{id}")
          Provider.auth?(id, token) ? session[:provider_id] = id : unauthenticated!
        else
          unauthenticated!
        end
      end
    end

    def proper_request?
      if auth.provided?
        if auth.basic?
          true
        else
          Log.info("auth not basic")
          false
        end
      else
        Log.info("auth not provided")
        false
      end
    end

    def authenticated?
      session[:provider_id]
    end

    def auth
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
    end

    def bad_request!
      throw(:halt, [400, enc_json("Bad Request")])
    end

    def unauthenticated!(realm="shushu.heroku.com")
      Log.info("#unauthenticated ip=#{request.env["REMOTE_ADDR"]} agent=#{request.env["HTTP_USER_AGENT"]}")
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, enc_json("Not authorized")])
    end

  end
end
