class ShuLog < Logger

  def error(*args)
    super(unparse(*args))
  end

  def info(*args)
    super(unparse(*args))
  end

  def info_t(hash)
    t0 = Time.now
    res = yield
    t1 = Time.now
    el = t1 - t0
    info(hash.merge({:elapsed_time => el}))
    res
  end

  def debug(*args)
    super(unparse(*args))
  end

  def unparse(data)
    if data.respond_to?(:map)
      data.map do |(k, v)|
        if (v == true)
          k.to_s
        elsif (v == false)
          "#{k}=false"
        elsif (v.is_a?(String) || v.is_a?(Symbol))
          "#{k}=#{CGI.escape(v)}"
        elsif v.is_a?(Float)
          "#{k}=#{format("%.3f", v)}"
        elsif v.is_a?(Numeric) || v.is_a?(Class) || v.is_a?(Module)
          "#{k}=#{v}"
        end
      end.compact.join(" ")
    else
      data
    end
  end

end
