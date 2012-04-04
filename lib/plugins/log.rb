module LogParser
  extend self

  def unparse(x)
    if x.values.any? {|v| [Array, Hash].include?(v.class)}
      raise(ArgumentError, "can not unparse #{x.class}")
    end
    Yajl::Encoder.encode(x)
  end

  def parse(x)
    Yajl::Decoder.decode(x)
  end
end

class ShuLog < Logger

  def error(*args)
    super(LogParser.unparse(*args))
  end

  def info(*args)
    super(LogParser.unparse(*args))
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
    super(LogParser.unparse(*args))
  end

end
