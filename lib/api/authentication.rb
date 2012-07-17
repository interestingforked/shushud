require './lib/provider'

module Api
  module Authentication
    include Helpers

    def authenticate_provider
      log(:fn => __method__) do
        return if head_request?
        unless authenticated?
          if proper_request?
            id, token = *auth.credentials
            if Shushu::Provider.auth?(id, token)
              log(:fn => __method__, :at => :authenticated, :provider_id => id)
              session[:provider_id] = params[:provider_id] = id
            else
              log(:fn => __method__, :at => :unauthenticated,
                   :id => id, :ip => ip, :agent => agent)
              unauthenticated!
            end
          else
            log(:fn => __method__, :at => "bad-request",
                 :ip => ip, :agent => agent)
            unauthenticated!
          end
        end
      end
    end

    def head_request?
      request.request_method == "HEAD"
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

    def ip
      request.env["REMOTE_ADDR"]
    end

    def agent
      request.env["HTTP_USER_AGENT"]
    end

  end
end
