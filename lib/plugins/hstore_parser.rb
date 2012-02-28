# thanks @pvh

module HstoreParser
  extend self

  def quoted_string(scanner)
    key = scanner.scan(/(\\"|[^"])*/)
    key = key.gsub(/\\(.)/, '\1')
    scanner.skip(/"/)
    key
  end

  def parse_quotable_string(scanner)
    if scanner.scan(/"/)
      value = quoted_string(scanner)
    else
      value = scanner.scan(/\w+/)
      value = nil if value == "NULL"
      # TODO: values but not keys may be NULL
    end
  end

  def skip_key_value_delimiter(scanner)
    scanner.skip(/\s*=>\s*/)
  end

  def skip_pair_delimiter(scanner)
    scanner.skip(/,\s*/)
  end

  def parse(string)
    hash = {}

    # remove single quotes around literal if necessary
    string = string[1..-2] if string[0] == "'" and string[-1] == "'"

    scanner = StringScanner.new(string)
    while !scanner.eos?
      k = parse_quotable_string(scanner)
      skip_key_value_delimiter(scanner)
      v = parse_quotable_string(scanner)
      skip_pair_delimiter(scanner)
      # controversial...
      # to_sym, or what?
      hash[k.to_sym] = v
    end
    hash
  end

end

