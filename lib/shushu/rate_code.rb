class RateCode < Sequel::Model

  PUBLIC_ATTRS = [:slug, :rate, :description]
  
  def api_values
    values.select {|v| PUBLIC_ATTRS.include?(v)}
  end
  
end
