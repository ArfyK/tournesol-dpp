using Statistics
using LinearAlgebra
using Dates

using DataFrames
using CSV
using Plots

using Determinantal 


include("utils.jl")


#Data set up
df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))
tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))
quantile_95 = quantile!(tournesol_scores, 0.95)
quantile_50 = quantile!(tournesol_scores, 0.50)

tournesol_scores_powers = range(1, 10)

for power in tournesol_scores_powers
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
	sample_size = 1000
	bundle_size = 9
	results = Array{Number, 2}(undef, sample_size, 2)

	for i in 1:sample_size
		indexes = sample(L, bundle_size)
		top_5percent_count = sum(tournesol_scores[indexes].>=quantile_95)
		bottom_50percent_count = sum(tournesol_scores[indexes].<=quantile_50)
		results[i,:] = [top_5percent_count, bottom_50percent_count]
	end


