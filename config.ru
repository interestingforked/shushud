require "./lib/shushu"

use Rack::CommonLogger

map "/" do
  run Api::Http
end