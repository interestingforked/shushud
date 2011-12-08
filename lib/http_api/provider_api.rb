class ProviderApi < Sinatra::Application

  helpers { include Authentication }
  
  before do
    authenticate_provider
  end

  post "/:target_provider_id/rate_codes" do
    target_provider = Provider[params[:target_provider_id]]
    provider = Provider[params[:provider_id]]

    if provider.root?
      rate_code = RateCode.new({
        :provider_id => params[:target_provider_id],
        :rate => params[:rate_code][:rate],
        :description => params[:rate_code][:description]
      })
      if rate_code.save
        status(201)
        body(JSON.dump(rate_code.api_values))
      else
        status(422)
        body(JSON.dump({:message => "Could not save rate_code"}))
      end
    else
      status(403)
      body(JSON.dump({:message => "Provider does not have root access."}))
    end
  end

end

