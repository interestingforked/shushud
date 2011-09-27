class ResourceHistory < ActiveRecord::Base
    
  CURRENT_VERSION = 2

  # validates_presence_of :resource, :qty, :rate, :rate_period, :version
  # validates_numericality_of :qty, :greater_than_or_equal_to => 0, :only_integer => true

  named_scope :open,       :conditions => "ended_at IS NULL"
  named_scope :closed,     :conditions => "ended_at IS NOT NULL"

  named_scope :within, lambda { |from, to|
    { :conditions => ["created_at < ? AND (ended_at IS NULL OR ended_at > ?)", to, from] }
  }

  named_scope :by_addon, lambda { |addon| {
    :conditions => {
      :resource    => 'addon',
      :subresource => addon.addon_name
    }
  }}

  named_scope :by_partner, lambda { |partner| {
    :conditions => {
      :resource    => 'addon',
      :subresource => partner.addons.map(&:addon_name)
    }
  }}

  named_scope :dynohours_by_app, lambda { |app_id|
    { :conditions => ["app_id = ? AND resource = 'dyno' AND subresource IS NOT NULL", app_id] }
  }

  # exclude users flagged as billing exception
  named_scope :paid, lambda {
    exceptions = Payments::BillingException.all.map(&:session_key)
    users      = User.find_all_by_payment_session_key(exceptions)
    {
      :conditions => ['user_id NOT IN (?)', users.map(&:id)]
    } unless users.empty?
  }

  named_scope :by_upid, lambda {|upid| {
    :conditions => ["upid = ?", upid.to_s]
  }}

  named_scope :by_version, lambda {|v| {
    :conditions => ["version = ?", v]
    }}

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

  def self.open_new_dyno(app_id, subresource, command, rate, rate_period, upid)
    if by_upid(upid).count == 0
      create!(
        :app_id      => app_id,
        :resource    => "dyno",
        :subresource => subresource,
        :command     => command,
        :qty         => 1,
        :rate        => rate,
        :rate_period => rate_period,
        :upid        => upid,
        :version     => 3
      )
    end
  end

  def self.legacy_open_new(app_id,user_id,res_id,resource,subresource,qty,rate,rate_period,beta_status,notes,upid)
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
      :version     => 2
    )
    new_rh.close_previous
    new_rh
  end

  def self.close(upid)
    if rh = find_by_upid(upid)
      if rh.ended_at.nil?
        rh.update_attribute(:ended_at, Time.now)
      end
    end
  end

  def self.close_resource_histories(app,time)
    app.resource_histories.open.each do |rh|
      rh.update_attribute :ended_at, time
    end
  end

  def self.get_dynohours(app_id)
    now = Time.now
    dynohours = Hash.new(0)
    dynohours_by_app(app_id).by_version(3).each do |rh|
      dynohours[rh.subresource] += rh.dyno_hours(now.beginning_of_month, now)
    end
    dynohours
  end

  def to_s
    if ended_at
      status = sprintf("%.dh", hours)
    else
      status = "open"
    end

    [
      id.to_s.ljust(9),
      created_at.to_formatted_s(:db),
      ended_at_or_now.to_formatted_s(:db),
      resource.ljust(9),
      (subresource || '').ljust(32),
      qty.to_s.ljust(3),
      AddonPrice.new(rate, rate_period).formatted_inline.ljust(13),
      status,
    ].join(' ')
  end

  def description(from=nil, to=nil)
    from, to = scope(from, to)
    if resource == "addon"
      t = time_units(from, to)
      desc_str = []
      desc_str << "#{qty}x " if qty > 1
      desc_str << subresource.titleize + " - "
      desc_str << case rate_period
        when 'hour'
          "#{rate_as_dollars} for #{sprintf("%.2f", t)} hours"
        when 'month'
          "#{rate_as_dollars} per month = #{ sprintf("%.2f", t * 100)}%"
        when 'dynohour'
          "#{rate_as_dollars} over #{sprintf("%.2f", t)} dyno-hours"
      end
      desc_str.join("")
    else
      "#{pluralize(qty, resource)} for %0.2f hour#{period_pluralized? ? "s" : ""} @ #{rate_as_dollars} per hour" % hours(from, to)
    end
  end

  def rate_as_dollars
    "$%0.2f" % (BigDecimal.new(rate.to_s)/100)
  end

  def period_pluralized?
    hours > 1
  end

  def scoped_time_units(from,to)
    from, to = scope(from,to)
    time_units(from,to)
  end

  def time_units(start, finish)
    case rate_period
      when 'hour'
        (finish - start) / 1.hour
      when 'month'
        if (finish -1).month == start.month
          (finish - start) / ((start + 1.month).beginning_of_month - start.beginning_of_month)
        else # assume worse case
          (finish - start) / 31.days
        end
      when 'dynohour'
        dynohours_for_period(start, finish)
      else
        raise "Don't know how to calculate total for rate_period: #{rate_period}"
    end
  end

  def closed?
    !ended_at.nil?
  end

  def ended_at_or_now
    ended_at || Time.now
  end

  def total(from=nil,to=nil)
    raise ArgumentError if to && to > Time.now #can't give total for future
    from, to = scope(from, to)
    rate * time_units(from,to)
  end

  def duration(from=nil, to=nil)
    from, to = scope(from, to)
    to - from
  end

  def hours(from=nil,to=nil)
    duration(from, to) / 1.hour
  end

  def dyno_hours(from,to)
    if resource == "dyno"
      ((qty * duration(from,to)) / 1.hour).round(2)
    else
      0
    end
  end

  def dynohours_for_period(from, to)
    app.resource_histories.by_version(2).within(from,to).find_all_by_resource('dyno').map do |rh|
      rh.qty * rh.duration(from,to) / 1.hour
    end.sum
  end

  def close_previous
    conditions = [ "id != ? and ended_at IS NULL and resource=?", id, resource ]
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

  def resource=(resource)
    super(resource.to_s)
  end

  def extract_ip
    self.ip ||= user.current_ip if user
  end

  def scoped_to(to)
    [to, ended_at_or_now].compact.min
  end

  def scoped_from(from)
    [from, created_at].compact.max
  end

  def scope(from, to)
    return scoped_from(from) , scoped_to(to)
  end

end
