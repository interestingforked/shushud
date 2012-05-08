$: << File.expand_path('lib')
require 'shushu'

Sequel.migration do
  up do
    Views = File.join(Shushu::Root, "/db/ddl/views.sql")
    file = File.open(Views)
    execute(file.read)
    file.close
  end
end
