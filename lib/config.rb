module Shushu
  module Config
    extend self

    def env(key)
      ENV[key]
    end

    def env!(key)
      env(key) || raise("missing #{key}")
    end

    def app_name; env("APP_NAME"); end
    def database_url; env!("DATABASE_URL"); end
    def follower_database_url; env!("FOLLOWER_DATABASE_URL"); end
    def port; env!("PORT").to_i; end

  end
end
