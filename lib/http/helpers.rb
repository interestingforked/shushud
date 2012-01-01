module Http
  module Helpers

    def status_based_on_verb(verb)
      case verb
      when "POST" then 201
      when "PUT"  then 200
      end
    end

    def enc_json(hash)
      Yajl::Encoder.encode(hash)
    end

    def dec_time(t)
      Time.parse(CGI.unescape(t.to_s))
    end

    def dec_int(i)
      i.to_i if i
    end

  end
end
