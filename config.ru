require './lib/shushu'
Rack::Handler::Thin.run(Http::Api, :Port => ENV["PORT"])
