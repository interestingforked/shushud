class ResourceOwnershipApi < Sinatra::Application

  helpers { include Authentication }

  before  do
    content_type(:json)
    authenticate_trusted_consumer
  end

  # This happens when someone queries for both account_id and hid.
  QueryMutexErr = Class.new(RuntimeError)

  get("/")    {perform(:query, query)}
  post("/")   {perform(:activate, account_id, hid)}
  # Transfer to new account and deactive use this endpoint.
  put("/")    {perform(:transfer, prev_account_id, account_id, hid)}

  def perform(method, *args)
    begin
      log("action=#{method}")
      rec = ResourceOwnershipService.send(method, *args)
      status(200)
      body({:hid => rec.hid, :account_id => rec.account_id})
    rescue ResourceOwnershipService::NoAccount
      status(404)
      body({:errors => ["could not find account"]})
    rescue QueryMutexErr
      status(422)
      body({:errors => ["please query by account_id XOR hid"]})
    rescue Exception => e
      log([e.inspect, e.backtrace].join)
      status(500)
      body({:errors => [e.inspect]})
    end
  end

  def body(hash)
    super(JSON.dump(hash))
  end

  def log(msg)
    shulog("api=resource_ownership_records_api account=#{account_id} hid=#{hid} #{msg}")
  end

  def query
    if !(account_id.nil? ^ hid.nil?)
      raise(QueryMutexErr, "Please choose account_id XOR hid")
    elsif account_id
      {:account_id => account_id}
    elsif hid
      {:hid => hid}
    end
  end

  def prev_account_id
    params[:prev_account_id]
  end

  def account_id
    params[:account_id]
  end

  def hid
    params[:hid]
  end

end
