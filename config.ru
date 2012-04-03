require './lib/shushu'
require "sinatra"

use Rack::CommonLogger
use Rack::Session::Cookie,
  :path            => "/",
  :key             => "shushu.session",
  :secret          => ENV["SESSION_SECRET"],
  :expire_after    => 120

map "/" do
  run Api::Events
end

map "/reports" do
  run Api::Reports
end
