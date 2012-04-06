class ShuLog < Logger

  def unparse(data)
    data.map do |(k, v)|
      if (v == true)
        "#{k}=true"
      elsif v.nil?
        nil
      else
        v_str = v.to_s
        if (v_str =~ /^[a-zA-z0-9\-\_\.]+$/)
          "#{k}=#{v_str}"
        else
          "#{k}=\"#{v_str}\""
        end
      end
    end.compact.join(" ")
  end

  def debug(data)
    super(unparse({:debug => true}.merge(data)))
  end

  def warn(data)
    super(unparse({:warn => true}.merge(data)))
  end

  def error(data)
    super(unparse({:error => true}.merge(data)))
  end

  def info(data)
    super(unparse({:info => true}.merge(data)))
  end

  def info_t(data)
    t0 = Time.now
    res = yield
    t1 = Time.now
    t = Integer((t1-t0)*1000)
    info(data.merge({:elapsed_time => t}))
    res
  end

end
