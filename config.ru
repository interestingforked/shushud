require './lib/shushu'
require "sinatra"

use Rack::CommonLogger
use Rack::Session::Dalli,
  :compression     => true,
  :key             => "shushu.session",
  :secret          => ENV["SESSION_SECRET"],
  :path            => "/",
  :expire_after    => ENV["SESSION_EXPIRE"]

run Api::Http
