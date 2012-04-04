class ShuLog < Logger

  def unparse(data)
    data.map do |(k, v)|
      if (v == true)
        "#{k}=true"
      elsif v.is_a?(Float)
        "#{k}=#{format("%.3f", v)}"
      elsif v.nil?
        nil
      else
        v_str = v.to_s
        if (v_str =~ /^[a-zA-z0-9\-\_\.]+$/)
          "#{k}=#{v_str}"
        else
          "#{k}=\"#{v_str.sub(/".*/, "...")}\""
        end
      end
    end.compact.join(" ")
  end

  def debug(data)
    super(unparse(data.merge(:debug => true)))
  end

  def error(data)
    super(unparse(data.merge(:error => true)))
  end

  def info(data)
    super(unparse(data.merge(:info => true)))
  end

  def info_t(data)
    t0 = Time.now
    res = yield
    t1 = Time.now
    el = t1 - t0
    info(data.merge({:elapsed_time => el}))
    res
  end

end
