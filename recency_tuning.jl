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
tournesol_scores_powers = range(start=1, length=20, stop=5)
caracteristic_times = range(start=30, length=10, stop=5000)
discount_coefficients = 1

results = zeros(length(tournesol_scores_powers), 9)
results[:,1] = tournesol_scores_powers
#2nd column will contain the average proportion of videos from the top 5%
#3rd column will contain the average proportion of videos from the bottom 50%
#4th column will contain the maximum selection frequency
#5th column will contain the minimum selection frequency 
#6th column will contain the average selection frequency of the top 5%
#7th column will contain the average selection frequency of the bottom 50%
#8th column will contain the average selection frequency of the top 20 from last month
#9nd column will contain the average proportion of videos from the top 20 of last month

for discount in discount_coefficients
	for caracteristic_time in caracteristic_times
		for (j, power) in zip(range(1,length(tournesol_scores_powers)), tournesol_scores_powers)
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

			results[j,[2 3 9]] = sum(counts, dims=1)./(sample_size*bundle_size)
			results[j,4] = maximum(video_selection_count)./sample_size
			results[j,5] = minimum(video_selection_count)./sample_size
			results[j,6] = mean(video_selection_count[top_5_percent_indexes])./sample_size
			results[j,7] = mean(video_selection_count[bottom_50_percent_indexes])./sample_size
			results[j,8] = mean(video_selection_count[top_20_last_month_indexes])./sample_size

			##Plots 
			p1=plot(
				results[:,1], 
				results[:,2], 
				seriestype=:scatter, 
				mc=:blue, 
				xlabel="power", 
				label="Top 5% proportion"
			)
			p2=plot(
				results[:,1], 
				results[:,3], 
				seriestype=:scatter, 
				mc=:green, 
				xlabel="power", 
				label="Bottom 50% proportion"
			)
			p3=plot(
				results[:,1], 
				[results[:,6] results[:,4] results[:, 8]],
				seriestype=:scatter, 
				xlabel="power", 
				ylabel="selection frequency", 
				label=["Top 5%" "Maximum" "Top 20"],
				yminorgrid=true
			)
			p4=plot(
				results[:,1], 
				[results[:,7], results[:, 5]],
				seriestype=:scatter, 
				xlabel="power", 
				ylabel="selection frequency", 
				label=["Bottom 50%" "Minimum"]
			)
			p5=plot(
				results[:,1], 
				results[:,9], 
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
	end
end

