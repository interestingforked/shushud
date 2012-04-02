$: << File.expand_path('lib')
require 'shushu'

Sequel.migration do
  up do
    Types = File.join(Shushu::Root, "/db/ddl/types.sql")
    Views = File.join(Shushu::Root, "/db/ddl/views.sql")
    Funcs = File.join(Shushu::Root, "/db/ddl/functions.sql")
    [Types, Views, Funcs].each do |f|
      file = File.open(f)
      execute(file.read)
      file.close
    end
  end
end
