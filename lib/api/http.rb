module Api
  class Http < Sinatra::Base
    include Authentication
    include Helpers

    register Sinatra::Instrumentation
    instrument_routes

    def perform
      begin
        s, b = yield
        status(s)
        body(enc_json(b))
      rescue RuntimeError, ArgumentError => e
        Log.error({:exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(400)
        body(enc_json(e.message))
      rescue Shushu::AuthorizationError => e
        Log.error({:exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(403)
        body(enc_json(e.message))
      rescue Shushu::NotFound => e
        Log.error({:exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(404)
        body(enc_json(e.message))
      rescue Shushu::DataConflict => e
        Log.error({:exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(409)
        body(enc_json(e.message))
      rescue Exception => e
        Log.error({:exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(500)
        body(enc_json(e.message))
        raise if Shushu.test?
      end
    end
  end
end
