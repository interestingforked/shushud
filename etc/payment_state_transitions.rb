PaymentService.setup_transitions do |transition|

  transition.to(:failed_no_action) do |opts|
    five_min_from_now = Time.now + (60*5)
    unless opts[:skip_retry]
      PaymentService.attempt(opts[:recid], opts[:pmid], five_min_from_now)
    end
  end

  transition.to(:failed_action) do
    puts("Payment failed, user action is required!")
  end

  transition.to(:success) do
    puts("Payment captured!")
  end
end
