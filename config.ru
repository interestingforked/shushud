require "./lib/shushu"

use Rack::CommonLogger

map "/" do
  run Api::Events
end

map "/reports" do
  run Api::Reports
end
