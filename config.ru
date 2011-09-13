require './lib/shushu'

shushu = Rack::Builder.new do
  map("/resources") { run Shushu::Web::Api }
end

Rack::Handler::Thin.run(shushu)
