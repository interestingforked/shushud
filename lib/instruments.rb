# Instruments enables out-of-the-box instrumentation
# on database & HTTP activities.
#
# You must provide a logger that responds to: info, warn and error.
# Ruby's Logger will do.
#
# require 'logger'
# Instruments.logger = Logger.new($stdout)
#
# Sinatra Example:
#
# register(Sinatra::Instrumentation)
# instrument_routes
# get "/hello/:name" do
#   params[:name]
# end
# => action="/hello/:name" elapsed_time=0.001
#
# Sequel Example:
#
# DB.loggers << Logger.new($stdout)
# DB.class.send(:include, Sequel::Instrumentation)
# DB[:events].count
# => action=select elapsed_time=0.1 sql="select count(*) from events"


require "sinatra/base"
require "sequel/database"

module Instruments
  def self.logger=(l)
    @logger = l
  end

  def self.logger
    @logger
  end

  module ::Sinatra
    module Instrumentation
      def route(verb, action, *) # in a modular app, do `def self.route`
        condition {@action = action} # will trigger in instance scope before route
        super
      end

      def instrument_routes
        before do
          @start_request = Time.now
        end
        after do
          t = Integer((Time.now - @start_request)*1000)
          Instruments.logger.info(:action => @action, :elapsed_time => t)
        end
      end
    end
    register(Instrumentation)
  end
  ::Sinatra::Base.send(:include, ::Sinatra::Instrumentation)

  module ::Sequel
    module Instrumentation
      def log_duration(t, sql)
        t = Integer(t*=1000)
        if t > PG_WARN_THREASHOLD
          Instruments.logger.warn(:action => action(sql), :time => t, :sql => sql)
        else
          Instruments.logger.info(:action => action(sql), :time => t, :sql => sql[0..20])
        end
      end

      def log_exception(e, sql)
        Instruments.logger.error(:exception => e.class, :sql => sql)
      end

      def action(sql)
        sql[/(\w+){1}/].downcase
      end
    end
  end
end
