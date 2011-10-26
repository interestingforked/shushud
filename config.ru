require './lib/shushu'
Rack::Handler::Thin.run(Shushu.web_api, :Port => ENV["PORT"])
