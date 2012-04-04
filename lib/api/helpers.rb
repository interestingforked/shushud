module Api
  module Helpers

    def dec_bool(string)
      case string 
      when /\A1|t|true\Z/i; true 
      when /\A0|f|false\Z/i; false
      else raise ArgumentError, "Boolean required"
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

    def enc_int(i)
      i.to_i if i
    end

    def enc_time(t)
      Time.parse(CGI.unescape(t.to_s)) if t
    end

  end
end
