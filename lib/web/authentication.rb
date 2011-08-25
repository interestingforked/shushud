module Shushu
  module Web
    module Authentication

      def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
      end

      def bad_request!
        throw(:halt, [400, 'Bad Request'])
      end

      def unauthenticated!(realm="shushu.heroku.com")
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end

      def authenticated?
        request.env["PROVIDER_ID"]
      end

      def authenticate(provider_id, provider_token)
        if provider = Provider.find(:id => provider_id)
          if provider.token == provider_token
            request.env["PROVIDER_ID"] = provider_id.to_i
            params[:provider_id] = provider_id.to_i
            true
          else
            false
          end
        else
          false
        end
      end

      def authenticate_provider
        return if authenticated?
        unauthenticated!  unless auth.provided?
        bad_request!      unless auth.basic?
        unauthenticated!  unless authenticate(*auth.credentials)
      end

    end
  end
end
