PaymentService.setup_transitions do |transition|

  transition.to(:failed_no_action) do |opts|
    five_days_from_now = Time.utc + (60*60*24*5)
    unless opts[:skip_retry]
      PaymentService.attempt(opts[:recid], opts[:pmid], five_days_from_now)
    end
  end

  transition.to(:failed_action) do
    puts("Payment failed, user action is required!")
  end

  transition.to(:success) do
    puts("Payment captured!")
  end
end
