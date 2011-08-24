module Shushu
  module EventCurator
    extend self

    def process(args={})
      BillableEvent::ATTRS.each do |k|
        raise(ArgumentError, "Missing #{k}") if !args.include?(k)
      end
      args[:provider_id] = args[:provider_id].to_i
      args[:qty] = args[:qty].to_i

      provider = Provider.find(:id => args[:provider_id])
      existing_event = BillableEvent.first(:provider_id => args[:provider_id], :event_id => args[:event_id])

      if existing_event
        if existing_event.similar?(args)
          [200, "Event has already been created."]
        else
          # You are submitting this event for a second time and it is
          # different from your first submission....
          tmp_existing = existing_event.values.dup
          tmp_args = args.dup
          [tmp_args, tmp_existing].map {|h| h.delete(:reality_to) }
          if args[:reality_to] and (tmp_existing == tmp_args)
            # You say it is ended and you only intend to change ended_at.
            if existing_event[:reality_from].nil?
              # Great! Thanks for closing this event.
              if existing_event.update(:reality_from => args[:reality_to])
                [200, existing_event.values]
              else
                [500, "Error"]
              end
            elsif args[:reality_to] == existing_event[:reality_from]
              # Thanks for closing this event a second time. We got it!
              [200, existing_event.values]
            else
              [409,"You are trying to change the ended_at."]
            end
          else
            # you are not trying to change ended_at and the attrs you do want to
            # change are not changeable.
            [422, "You are trying to change this event. We will only accept a change for ended_at."]
          end
        end
      else
        # I do not know about this event yet.
        new_event = BillableEvent.create(args)
        # Now I do.
        [201, new_event.values]
      end
    end

  end
end
