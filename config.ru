require './lib/shushu'
require "sinatra"

use Rack::CommonLogger
use Rack::Session::Dalli,
  :memcache_server => 'localhost:11211',
  :compression     => true,
  :key             => "shushu.session",
  :secret          => "change_me",
  :path            => "/",
  :expire_after    => 60*60

run Api::Http
