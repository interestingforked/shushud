module Shushu
  module Web
    module EventHttpHelper
      extend self

      def process!(event)
        log("enter process")
        if event.new?
          log("provess new event")
          if event.valid?
            log("new event is valid")
            if event.save
              log("new event saved")
              [201, "Event created. Event included in the current invoice period."]
            else
              [500, "Event was not created!"]
            end
          else
            log("new event is NOT valid")
            if event.late_submission?
              [412, "You are too late in reporting this event. #=> (created_at - Time.now).abs > 7.hours"]
            elsif event.past_cutoff?
              [412, "Event submitted past cut-off time."]
            end
          end
        else
          log("process existing event")
          if event.valid?
            log("existing event is valid")
            if event.only_modifying_reality_to? and event.save
              [200, "Event ended."]
            elsif event.save
              [200, "Event has already been created."]
            else
              [500, "Event was not created!"]
            end
          else
            log("existing event is NOT valid")
            [409, "You are trying to change a column other than ended_at."]
          end
        end
      end

      def log(msg)
        std_msg = ""
        LogJam.puts([std_msg, msg].join(" "))
      end

    end
  end
end
