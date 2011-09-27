require './lib/shushu'

shushu = Rack::Builder.new do
  map("/resources")  { run Api }
  map("/rate_codes") { run RateCodeApi }
  map("/providers")  { run ProviderApi }
end

Rack::Handler::Thin.run(shushu, :Port => ENV["PORT"])
