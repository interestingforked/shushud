$: << File.expand_path('lib')
require 'shushu'

Sequel.migration do
  up do
    SqlFunctions = File.join(Shushu::Root, "/db/ddl/functions.sql")
    file = File.open(SqlFunctions)
    execute(file.read)
    file.close
  end
end
