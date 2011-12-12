require './lib/shushu'
Rack::Handler::Thin.run(HttpApi, :Port => ENV["PORT"])
