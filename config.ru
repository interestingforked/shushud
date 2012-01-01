require './lib/shushu'
Rack::Handler::Thin.run(Api::Http, :Port => ENV["PORT"])
