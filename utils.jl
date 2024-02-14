using DataFrames
using CSV
using Plots

function plot_recency_results(
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

