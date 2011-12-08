class HeartbeatApi < Sinatra::Application

  helpers { include Authentication }

  get "/" do
    content_type :json
    authenticate_provider
    JSON.dump({:alive => Time.now})
  end

end
