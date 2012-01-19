require './lib/shushu'
require "sinatra"

use Rack::CommonLogger
use Rack::Session::Cookie,
  :key             => "shushu.session",
  :secret          => ENV["SESSION_SECRET"],
  :domain          => ENV["SESSION_DOMAIN"],
  :path            => "/",
  :expire_after    => ENV["SESSION_EXPIRE"]

run Api::Http
