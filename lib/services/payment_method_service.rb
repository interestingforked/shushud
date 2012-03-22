module PaymentMethodService
  extend self

  def handle_in(params)
    Shushu::DB.transaction do
      pm = find_or_create_pm(params)
      resolve_card(params, pm)
    end
  end

  private

  def find_or_create_pm(params)
    if s = params[:slug]
      pm = PaymentMethod.filter(:slug => s, :provider_id => params[:provider_id]).to_a
      case pm.length
      when 0
        PaymentMethod.create(:slug => s, :provider_id => params[:provider_id])
      when 1
        pm.pop
      else
        raise(Shushu::DataConflict, "Found #{pm.length} payment_methods with provider=#{params[:provider_id]} slug=#{s}")
      end
    else
      PaymentMethod.create(:slug => gen_slug, :provider_id => params[:provider_id])
    end
  end

  def resolve_card(params, pm)
    status, result = run_auth(params)
    CardToken.create(
      :provider_id => params[:provider_id],
      :payment_method_id => pm.id,
      :token => result[:card_token]
    )
    [status, result.merge(:id => pm.api_id)]
  end

  def run_auth(params)
    if t = params[:card_token]
      Log.debug("#payment_token_provided provider=#{params[:provider_id]}")
      # Assume the token is good and move on.
      [201, {:card_token => t}]
    else
      Log.debug("#payment_card_provided provider=#{params[:provider_id]}")
      Authorizer.run(params[:card_num], params[:card_exp_month], params[:card_exp_year])
    end
  end

  def gen_slug
    1
  end

end
