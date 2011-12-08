require './lib/shushu'
Rack::Handler::Thin.run(Shushu.http_api, :Port => ENV["PORT"])
