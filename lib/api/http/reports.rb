module Api
  class Reports < Http
    before {authenticate_provider; content_type(:json)}

    get "/res_diff/resources" do
      perform do
        ReportService.res_diff(
          dec_time(params[:lfrom]),
          dec_time(params[:lto]),
          dec_time(params[:rfrom]),
          dec_time(params[:rto]),
          dec_bool(params[:delta_increasing]),
          dec_bool(params[:lrev_zero]),
          dec_bool(params[:rrev_zero]),
          params[:limit]
        )
      end
    end

    get "/rev_report" do
      perform do
        ReportService.rev_report(dec_time(params[:from]), dec_time(params[:to]))
      end
    end
  end
end
