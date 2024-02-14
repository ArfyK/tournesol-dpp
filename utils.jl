using DataFrames
using CSV
using Plots

#Plots
function plot_general_results(df, discount_range, caracteristic_time_range, power_range)
	p1 = plot(df[:, :maximum_selection_frequency],
		  df[:,:prop_top_20_month], 
	          seriestype=:scatter,
	          ylabel="Top 20 proportion",
	          xlabel="Maximum selection frequency",
	          legend=false
	)
	p2 = plot(df[:, :discount],
		  df[:,:prop_top_20_month], 
	          seriestype=:scatter,
	          ylabel="Top 20 proportion",
	          xlabel="Discount",
	          legend=false,
		  mc=:red
	)
	p3 = plot(df[:, :caracteristic_time],
		  df[:,:prop_top_20_month], 
	          seriestype=:scatter,
	          ylabel="Top 20 proportion",
	          xlabel="Caracteristic time",
	          legend=false,
		  mc=:green
	)
	p4 = plot(df[:, :power],
		  df[:,:prop_top_20_month], 
	          seriestype=:scatter,
	          ylabel="Top 20 proportion",
	          xlabel="Power",
	          legend=false,
		  mc=:grey
	)
	plot(p1, 
	     p2, 
	     p3, 
	     p4,
	     layout=(2,2), 
	     grid=true,
	     size=(1080, 720),
	     plot_title="Discount in ["*string(Float64(discount_range.ref))*","*string(Float64(discount_range.ref+(discount_range.len-1)*discount_range.step))*"] "*
			"Caracteristic times in ["*string(Float64(caracteristic_time_range.ref))*","*string(Float64(caracteristic_time_range.ref+(caracteristic_time_range.len-1)*caracteristic_time_range.step))*"]\n"*
			"power_range_["*string(Float64(power_range.ref))*","*string(Float64(power_range.ref+(power_range.len-1)*power_range.step))*"]"
	)


	savefig("recency_tuning/General_results_"*
	"discount_["*string(Float64(discount_range.ref))*","*string(Float64(discount_range.ref+(discount_range.len-1)*discount_range.step))*"]_"*
	"caracteristic_time_range_["*string(Float64(caracteristic_time_range.ref))*","*string(Float64(caracteristic_time_range.ref+(caracteristic_time_range.len-1)*caracteristic_time_range.step))*"]_"*
	"power_range_["*string(Float64(power_range.ref))*","*string(Float64(power_range.ref+(power_range.len-1)*power_range.step))*
	  "].png"
	 )
end

function plot_parameters_sets_details(
			      df,
			      parameters_sets
			      )
	for parameter_set in eachrow(parameters_sets)
		subdf = filter(row->
			       (row.discount==parameter_set.discount)&&
			       (row.caracteristic_time==parameter_set.caracteristic_time),
			       df
			)

		p1=plot(
			subdf[:,:power], 
			subdf[:,:prop_top_5], 
			seriestype=:scatter, 
			mc=:blue, 
			xlabel="power", 
			label="Top 5% proportion"
		)
		p2=plot(
			subdf[:,:power],
			subdf[:,:prop_bottom_50],
			seriestype=:scatter, 
			mc=:green, 
			xlabel="power", 
			label="Bottom 50% proportion"
		)
		p3=plot(
			subdf[:,:power],
			[subdf[:,:average_top_5_selection_frequency] subdf[:,:maximum_selection_frequency] subdf[:, :average_top_20_month_selection_frequency]],
			seriestype=:scatter, 
			xlabel="power", 
			ylabel="selection frequency", 
			label=["Top 5%" "Maximum" "Top 20"],
			yminorgrid=true
		)
		p4=plot(
			subdf[:,:power],
			[subdf[:,:average_bottom_50_selection_frequency], subdf[:, :minimum_selection_frequency]],
			seriestype=:scatter, 
			xlabel="power", 
			ylabel="selection frequency", 
			label=["Bottom 50%" "Minimum"]
		)
		p5=plot(
			subdf[:,:power],
			subdf[:,:prop_top_20_month], 
			seriestype=:scatter, 
			mc=:blue, 
			xlabel="power", 
			label="Top 20 proportion"
		)
		plot(p1, 
		     p2, 
		     p3, 
		     p4,
		     p5,
		     layout=(3,2), 
		     grid=true,
		     size=(900, 600),
		     plot_title=" Discount="*string(parameter_set.discount)*
		     " tau="*string(parameter_set.caracteristic_time)
		)
		savefig("recency_tuning/"*
			"Discount="*string(parameter_set.discount)*
			"_tau="*string(parameter_set.caracteristic_time)*
			".png"
		)
	end
end

