module EventTracker
  extend self

  def track(args)
    if eid = args[:entity_id]
      if r = Shushu::DB[:open_events].first(:entity_id => eid)
        Shushu::DB[:open_events].filter(:entity_id => r[:entity_id]).delete
      else
        Shushu::DB[:open_events].insert(args)
      end
    end
  end

end

