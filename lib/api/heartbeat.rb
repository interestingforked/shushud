module Api
  class HeartBeat < Sinatra::Base

    include Helpers

    get "/pub_heartbeat" do
      status(200)
      body(enc_json({:alive => Time.now})
    end

  end
end
