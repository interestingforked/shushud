module Api
  module Authentication
    include Helpers

    def authenticate_provider
      unless authenticated?
        if proper_request?
          id, token = *auth.credentials
          if Provider.auth?(id, token)
            session[:provider_id] = params[:provider_id] = id
          else
            unauthenticated!
          end
          Log.info(:action => "authenticated", :provider => id)
        else
          ip, agent = request.env["REMOTE_ADDR"], request.env["HTTP_USER_AGENT"]
          Log.info(:action => "unauthenticated", :ip => ip, :agent => agent)
          unauthenticated!
        end
      end
    end

    def proper_request?
      auth.provided? && auth.basic?
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
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, enc_json("Not authorized")])
    end

  end
end
