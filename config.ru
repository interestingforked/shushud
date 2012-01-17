require './lib/shushu'

use Rack::Session::Dalli,
  :memcache_server => 'localhost:11211',
  :compression     => true,
  :key             => "shushu.session",
  :secret          => "change_me",
  :path            => "/",
  :expire_after    => 60*60

run Api::Http
