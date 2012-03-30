module EventTracker
  extend self

  def track(entity_id, state)
    if entity_id
      if r = Shushu::DB[:open_events].first(:entity_id => entity_id)
        Shushu::DB[:open_events].filter(:entity_id => r[:entity_id]).delete
      else
        Shushu::DB[:open_events].insert(:entity_id => entity_id, :state => state)
      end
    end
  end

end

