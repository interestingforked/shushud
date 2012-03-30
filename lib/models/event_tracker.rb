module EventTracker
  extend self

  def track(entity_id, state)
    if entity_id
      if r = Shushu::DB[:open_events].first(:entity_id => entity_id)
        r.destroy
      else
        Shushu::DB[:open_events].insert(:entity_id => entity_id, :state => state)
      end
    end
  end

end

