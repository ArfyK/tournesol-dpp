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

#Data set up
df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))

criteria_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))
quantile_95 = quantile!(tournesol_scores, 0.95)
quantile_50 = quantile!(tournesol_scores, 0.50)

sample_size = 1000
bundle_size = 9
tournesol_scores_powers = range(1, 10)

results = Array{Number, 2}(undef, length(tournesol_scores_powers), 4)
results[:,1] = tournesol_scores_powers
#Second column will contain the total number of videos from the top 5%
#Third column will contain the total number of videos from the bottom 50%
#Fourth column will contain the maximum selection frequency

for (j, power) in zip(range(1,length(tournesol_scores_powers)), tournesol_scores_powers)
	#Quality model
	qualities = tournesol_scores.^power
		
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
	counts = Array{Number, 2}(undef, sample_size, 2) #number of top5% and bottom 50% in each bundle
	video_selection_count = zeros(length(tournesol_scores))
	for i in 1:sample_size
		indexes = sample(L, bundle_size)
		top_5percent_count = sum(tournesol_scores[indexes].>=quantile_95)
		bottom_50percent_count = sum(tournesol_scores[indexes].<=quantile_50)
		counts[i,:] = [top_5percent_count, bottom_50percent_count]
		video_selection_count[indexes] .+= 1
	end

	results[j,2:3] = sum(counts, dims=1)
	results[j,4] = maximum(video_selection_count)./sample_size
end

##Plots 
#Top 5%
p1=plot(
	results[:,1], 
	results[:,2], 
	seriestype=:scatter, 
	mc=:blue, 
	xlabel="power", 
	ylabel="Total", 
	legend=false,
	title="Top 5%"
	)
p3=plot(
	results[:,1], 
	results[:,2]./sample_size, 
	seriestype=:scatter, 
	mc=:blue, 
	xlabel="power", 
	ylabel="Mean count per bundle", 
	legend=false
	)
p2=plot(
	results[:,1], 
	results[:,3], 
	seriestype=:scatter, 
	mc=:red, 
	xlabel="power", 
	ylabel="Total", 
	legend=false,
	title="bottom 50%"
	)
p4=plot(
	results[:,1], 
	results[:,3]./sample_size, 
	seriestype=:scatter, 
	mc=:red, 
	xlabel="power", 
	ylabel="Total", 
	legend=false
	)
p5=plot(
	results[:,1], 
	results[:,4], 
	seriestype=:scatter, 
	mc=:green, 
	xlabel="power", 
	ylabel="Maximum selection frequency", 
	legend=false
	)


plot(p1, 
     p2, 
     p3, 
     p4,
     p5,
     layout=(3,2), 
     legend=false, 
    )
savefig("power_tuning/"*
	"bundlesize="*string(bundle_size)*
	"_samplesize="*string(sample_size)*
	".png"
	)
