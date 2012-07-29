require './lib/utils'
require './lib/provider'

module Shushu
  module Authentication

    def authenticate_provider
      log(fn: __method__) do
        # Allow unauthenticated access for things like
        # pingdom and healthchecks.
        return if head_request?
        unless authenticated?
          if proper_request?
            id, token = *auth.credentials
            if Provider.auth?(id, token)
              log(fn: __method__, at: "authenticated", provider_id: id)
              session[:provider_id] = params[:provider_id] = id
            else
              log(fn: __method__, at: "unauthenticated", id: id, ip: ip)
              unauthenticated!
            end
          else
            log(fn: __method__, at: "bad-request", ip: ip)
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
      throw(:halt, [400, Utils.enc_j("Bad Request")])
    end

    def unauthenticated!(realm="shushu.heroku.com")
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, {msg: "Not authorized"}])
    end

    def ip
      request.env["REMOTE_ADDR"]
    end

  end
end
