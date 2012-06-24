module Api
  module Health
    class Http < Sinatra::Base
      head "/" do
        status(200)
        body(nil)
      end
    end
  end
end
