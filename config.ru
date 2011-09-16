require './lib/shushu'

shushu = Rack::Builder.new do
  map("/resources")  { run Shushu::Web::Api }
  map("/rate_codes") { run Shushu::Web::RateCodeApi }
  map("/providers") 
end

Rack::Handler::Thin.run(shushu)
