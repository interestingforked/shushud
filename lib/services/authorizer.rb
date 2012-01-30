module Authorizer
  extend self

  def run(*args)
    [201, {:ok => true}]
  end
end
