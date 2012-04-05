module Api
  class Reports < Http
    before {authenticate_provider; content_type(:json)}

    get "/res_diff" do
      perform do
        ReportService.res_diff_agg(*res_diff_params)
      end
    end

    get "/res_diff/resources" do
      perform do
        _res_diff_params = res_diff_params << dec_int(params[:limit])
        ReportService.res_diff(*(_res_diff_params))
      end
    end

    get "/revenue" do
      perform do
        ReportService.rev_report(dec_time(params[:from]), dec_time(params[:to]))
      end
    end

    def res_diff_params
      [
        dec_time(params[:lfrom]),
        dec_time(params[:lto]),
        dec_time(params[:rfrom]),
        dec_time(params[:rto]),
        dec_bool(params[:delta_increasing]),
        dec_bool(params[:lrev_zero]),
        dec_bool(params[:rrev_zero])
       ]
    end
  end
end
