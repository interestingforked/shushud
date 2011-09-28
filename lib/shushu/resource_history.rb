class ResourceHistory < ActiveRecord::Base
  # validates_presence_of :resource, :qty, :rate, :rate_period, :version
  # validates_numericality_of :qty, :greater_than_or_equal_to => 0, :only_integer => true

  named_scope :open,       :conditions => "ended_at IS NULL"
  named_scope :closed,     :conditions => "ended_at IS NOT NULL"

  named_scope :within, lambda { |from, to|
    { :conditions => ["created_at < ? AND (ended_at IS NULL OR ended_at > ?)", to, from] }
  }

  named_scope :by_upid, lambda {|upid| {
    :conditions => ["upid = ?", upid.to_s]
  }}

  named_scope :by_version, lambda {|v| {
    :conditions => ["version = ?", v]
  }}

  def self.open(app_id,user_id,res_id,resource,subresource,qty,rate,rate_period,beta_status,notes,upid)
    new_rh = create!(
      :upid        => upid,
      :app_id      => app_id,
      :user_id     => user_id,
      :resource_id => res_id,
      :resource    => resource,
      :subresource => subresource,
      :qty         => qty,
      :rate        => rate,
      :rate_period => rate_period,
      :beta        => beta_status,
      :notes       => notes,
      :version     => 4
    )
    new_rh.close_previous
    new_rh
  end

  def close_previous
    conditions = ["id != ? and ended_at IS NULL and resource=?", id, resource ]

    if resource_id
      conditions[0] += " and resource_id=?"
      conditions << resource_id
    else
      conditions[0] += " and app_id=? AND resource_id IS NULL"
      conditions << app_id
    end

    if resource == 'addon'
      conditions[0] += " and subresource=?"
      conditions << subresource
    end

    ResourceHistory.by_version(2).update_all ["ended_at = ?", created_at], conditions
  end

  def self.close(upid)
    if rh = find_by_upid(upid)
      if rh.ended_at.nil?
        rh.update_attribute(:ended_at, Time.now)
      end
    end
  end

  def api_values
    {
      :provider_id => user_id,
      :event_id    => upid,
      :resource_id => app_id.to_s,
      :rate_code   => rate_code_slug,
      :qty         => qty,
      :from        => reality_from.to_s,
      :to          => reality_to.to_s
    }
  end

  def reality_from
    self[:created_at]
  end

  def reality_to
    self[:ended_at]
  end

  def rate_code_id
    self[:rate]
  end

  def rate_code_id=(i)
    self[:rate] = i
  end

  def rate_code_slug
    RateCode.filter(:id => rate_code_id).first.slug
  end

end
