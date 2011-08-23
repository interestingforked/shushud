module Shushu
  module EventCurator
    extend self

    def process(resource_id, event_id, event_params)
      be_params = event_params.merge({:event_id => event_id, :resource_id => resource_id})
      event = BillableEvent.new(be_params)

      yield(
        if event.valid?
          if event.created_at
            http_helper(200, event.to_hash)
          else
            http_helper(201, event.to_hash)
          end
        else
          http_helper(422, "Invalid Data")
        end
      )
    end

    def http_helper(status, body)
      OpenStruct.new({:status => status, :body => body})
    end

  end
end
