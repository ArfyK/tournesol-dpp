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
top_5_percent_indexes = findall(x->x>=quantile_95, tournesol_scores)
bottom_50_percent_indexes = findall(x->x<=quantile_50, tournesol_scores)

#Test parameters
sample_size = 1000
bundle_size = 9
tournesol_scores_powers = range(start=1, length=20, stop=5)

results = Array{Number, 2}(undef, length(tournesol_scores_powers), 7)
results[:,1] = tournesol_scores_powers
#2nd column will contain the total number of videos from the top 5%
#3rd column will contain the total number of videos from the bottom 50%
#4th column will contain the maximum selection frequency
#5th column will contain the minimum selection frequency 
#6th column will contain the average selection frequency of the top 5%
#7th column will contain the average selection frequency of the bottom 50%

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
	results[j,5] = minimum(video_selection_count)./sample_size
	results[j,6] = mean(video_selection_count[top_5_percent_indexes])./sample_size
	results[j,7] = mean(video_selection_count[bottom_50_percent_indexes])./sample_size
end

##Plots 
#Top 5%
p1=plot(
	results[:,1], 
	results[:,2]./(sample_size*bundle_size), 
	seriestype=:scatter, 
	mc=:blue, 
	xlabel="power", 
	label="Top 5% proportion"
	)
p2=plot(
	results[:,1], 
	results[:,3]./(sample_size*bundle_size), 
	seriestype=:scatter, 
	mc=:green, 
	xlabel="power", 
	label="Bottom 50% proportion"
	)
p3=plot(
	results[:,1], 
	[results[:,6] results[:,4]],
	seriestype=:scatter, 
	xlabel="power", 
	ylabel="selection frequency", 
	label=["Top 5%" "Maximum"]
	)
p4=plot(
	results[:,1], 
	[results[:,7], results[:, 5]],
	seriestype=:scatter, 
	xlabel="power", 
	ylabel="selection frequency", 
	label=["Bottom 50%" "Minimum"]
	)
plot(p1, 
     p2, 
     p3, 
     p4,
     layout=(2,2), 
     grid=true,
     size=(900, 600)
    )
savefig("power_tuning/"*
	"bundlesize="*string(bundle_size)*
	"_samplesize="*string(sample_size)*
	".png"
	)
