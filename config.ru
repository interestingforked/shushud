require './lib/shushu'
use Rack::Session::Dalli, :memcache_server => 'localhost:11211', :compression => true
run Api::Http
#Rack::Handler::Thin.run(Api::Http, :Port => ENV["PORT"])
