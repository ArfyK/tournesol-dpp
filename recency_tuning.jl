using Statistics
using LinearAlgebra
using Dates

using DataFrames
using CSV
using Plots

using Determinantal 

CRITERIA = [
    "reliability",
    "importance",
    "engaging",
    "pedagogy",
    "layman_friendly",
    "entertaining_relaxing",
    "better_habits",
    "diversity_inclusion",
    "backfire_risk",
]#the tournesol score is not included in the criteria

function get_age_in_days(date::AbstractString, ref_date::Date)::Int
	return max((ref_date - Date(date[1:10], dateformat"yyyy-mm-dd")).value, 1)
	end

#Data set up
df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))

criteria_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))
quantile_95 = quantile!(tournesol_scores, 0.95)
quantile_50 = quantile!(tournesol_scores, 0.50)
top_5_percent_indexes = findall(x->x>=quantile_95, tournesol_scores)
bottom_50_percent_indexes = findall(x->x<=quantile_50, tournesol_scores)

ref_date = Date("2023-09-19", dateformat"yyyy-mm-dd")#one day older than the database
ages_in_days = get_age_in_days.(df[:, :publication_date], ref_date)
#Hack to get the indices from the top 20 of last month 
#without using dataframes operations...
last_month_indexes = findall(x->x<=30, ages_in_days)
top_20_last_month_minimum_score = sort(tournesol_scores[last_month_indexes], rev=true)[20]
is_less_than_30_days_old = ages_in_days .<= 30
is_more_than_minimum_score = tournesol_scores.>=top_20_last_month_minimum_score
top_20_last_month_indexes = findall(
				    x->x==1,
				    is_less_than_30_days_old.*is_more_than_minimum_score
				    )

#Test parameters
sample_size = 1000
bundle_size = 9

selection_frequency_limit = 0.2
minimum_top_20_proportion = 0.1
maximum_top_20_proportion = 0.3

#=
tournesol_scores_powers = range(start=1, length=20, stop=5)
caracteristic_times = range(start=1, length=100, stop=5000)
discount_coefficients = range(start=1e-3, length=100, stop=100)
=#

tournesol_scores_powers = range(start=1, length=2, stop=5)
caracteristic_times = range(start=30, length=2, stop=100)
discount_coefficients = range(start=1, length=2, stop=10)

filtered_results = DataFrame(
			     discount=Float64[],
			     caracteristic_time=Float64[],
			     power=Float64[],
			     prop_top_5=Float64[],
			     prop_bottom_50=Float64[],
			     prop_top_20_month=Float64[],
			     maximum_selection_frequency=Float64[],
			     minimum_selection_frequency=Float64[],
			     average_top_5_selection_frequency=Float64[],
			     average_bottom_50_selection_frequency=Float64[],
			     average_top_20_month_selection_frequency=Float64[],
			     )
#Tests
n_parameter_sets = discount_coefficients.len*caracteristic_times.len*tournesol_scores_powers.len
current_parameter_set = 0

for discount in discount_coefficients
	for caracteristic_time in caracteristic_times
		for (j, power) in zip(range(1,length(tournesol_scores_powers)), tournesol_scores_powers)
			#Indication about the remaining tests
			global current_parameter_set += 1
			println("Testing parameter set "*string(current_parameter_set)*" out of "*string(n_parameter_sets))

			#Quality model
			qualities = (1 .+discount.*exp.(-ages_in_days./caracteristic_time)).*tournesol_scores.^power
				
			#Diversity model
			criteria_scores_norms = sqrt.(sum(abs2, criteria_scores, dims=2)) 
			normed_criteria_scores = criteria_scores
			for i in 1:size(criteria_scores)[1]
				if criteria_scores_norms[i] > 0.0
					normed_criteria_scores[i,:] /= criteria_scores_norms[i]
				end
			end

			#Construct L-Ensemble
			X = Diagonal(qualities)*normed_criteria_scores
			K = LowRank(X)
			L =  EllEnsemble(K)

			#Sample
			counts = zeros(sample_size, 3) #number of top5%, bottom 50% and top 20 from last month in each bundle
			video_selection_count = zeros(length(tournesol_scores))
			for i in 1:sample_size
				indexes = sample(L, bundle_size)
				top_5percent_count = sum(tournesol_scores[indexes].>=quantile_95)
				bottom_50percent_count = sum(tournesol_scores[indexes].<=quantile_50)
				top_20_from_last_month_count = length(intersect(indexes, top_20_last_month_indexes))
				counts[i,:] = [top_5percent_count, 
					       bottom_50percent_count, 
					       top_20_from_last_month_count
					       ]
				video_selection_count[indexes] .+= 1
			end

			(top_5_proportion, bottom_50_proportion, top_20_proportion) = sum(counts, dims=1)./(sample_size*bundle_size)
			maximum_selection_frequency = maximum(video_selection_count)./sample_size

			if (top_20_proportion>=minimum_top_20_proportion)&& #Filter the results
				(top_20_proportion<=maximum_top_20_proportion)&&
				(maximum_selection_frequency <= selection_frequency_limit)
				push!(filtered_results,
				      (discount,
				       caracteristic_time,
				       power,
				       top_5_proportion,
				       bottom_50_proportion,
				       top_20_proportion,
				       maximum_selection_frequency, 
				       minimum(video_selection_count)./sample_size,
				       mean(video_selection_count[top_5_percent_indexes])./sample_size,
				       mean(video_selection_count[bottom_50_percent_indexes])./sample_size,
				       mean(video_selection_count[top_20_last_month_indexes])./sample_size
				       )
				      )
			end
		end
		#=Plots 
		subset_filtered_results = filter(
						 row->(row.discount==discount)
						 &&(row.caracteristic_time==caracteristic_time),
						 filtered_results
						 )
		if !isempty(subset_filtered_results)
			p1=plot(
				subset_filtered_results[:,:power], 
				subset_filtered_results[:,:prop_top_5], 
				seriestype=:scatter, 
				mc=:blue, 
				xlabel="power", 
				label="Top 5% proportion"
			)
			p2=plot(
				subset_filtered_results[:,:power],
				subset_filtered_results[:,:prop_bottom_50],
				seriestype=:scatter, 
				mc=:green, 
				xlabel="power", 
				label="Bottom 50% proportion"
			)
			p3=plot(
				subset_filtered_results[:,:power],
				[subset_filtered_results[:,:average_top_5_selection_frequency] subset_filtered_results[:,:maximum_selection_frequency] subset_filtered_results[:, :average_top_20_month_selection_frequency]],
				seriestype=:scatter, 
				xlabel="power", 
				ylabel="selection frequency", 
				label=["Top 5%" "Maximum" "Top 20"],
				yminorgrid=true
			)
			p4=plot(
				subset_filtered_results[:,:power],
				[subset_filtered_results[:,:average_bottom_50_selection_frequency], subset_filtered_results[:, :minimum_selection_frequency]],
				seriestype=:scatter, 
				xlabel="power", 
				ylabel="selection frequency", 
				label=["Bottom 50%" "Minimum"]
			)
			p5=plot(
				subset_filtered_results[:,:power],
				subset_filtered_results[:,:prop_top_20_month], 
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
			     plot_title=" Discount="*string(discount)*
			     " tau="*string(caracteristic_time)
			)
			savefig("recency_tuning/"*
				"bundlesize="*string(bundle_size)*
				"_samplesize="*string(sample_size)*
				" Discount="*string(discount)*
				" tau="*string(caracteristic_time)*
				".png"
			)
		end
		=#
	end
end

plot(
     filtered_results[:,:prop_top_20_month], 
     filtered_results[:, :maximum_selection_frequency],
     seriestype=:scatter,
     xlabel="Top 20 proportion",
     ylabel="Maximum selection frequency",
     legend=false
    )
savefig("recency_tuning/top20_prop_vs_max_selection_freq_"*
	"discount_["*string(Float64(discount_coefficients.ref))*","*string(Float64(discount_coefficients.ref+(discount_coefficients.len-1)*discount_coefficients.step))*"]_"*
	"caracteristic_times_["*string(Float64(caracteristic_times.ref))*","*string(Float64(caracteristic_times.ref+(caracteristic_times.len-1)*caracteristic_times.step))*"]_"*
	"tournesol_scores_powers_["*string(Float64(tournesol_scores_powers.ref))*","*string(Float64(tournesol_scores_powers.ref+(tournesol_scores_powers.len-1)*tournesol_scores_powers.step))*
	  "].png"
	  )

CSV.write("recency_tuning/filtered_results_"*
	  "discount_["*string(Float64(discount_coefficients.ref))*","*string(Float64(discount_coefficients.ref+(discount_coefficients.len-1)*discount_coefficients.step))*"]_"*
	  "caracteristic_times_["*string(Float64(caracteristic_times.ref))*","*string(Float64(caracteristic_times.ref+(caracteristic_times.len-1)*caracteristic_times.step))*"]_"*
	  "tournesol_scores_powers_["*string(Float64(tournesol_scores_powers.ref))*","*string(Float64(tournesol_scores_powers.ref+(tournesol_scores_powers.len-1)*tournesol_scores_powers.step))*
	  "].csv",
	  filtered_results  
	  )
