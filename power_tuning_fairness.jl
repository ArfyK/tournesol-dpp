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
println("Setting up the dataset")

df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))

criteria_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))
quantile_95 = quantile!(tournesol_scores, 0.95)
quantile_50 = quantile!(tournesol_scores, 0.50)
top_5_percent_indexes = findall(x->x>=quantile_95, tournesol_scores)
bottom_50_percent_indexes = findall(x->x<=quantile_50, tournesol_scores)

#Test parameters
sample_size = 100000
bundle_size = 9
power = 2

frequencies = zeros(size(tournesol_scores))

println("Building the model")
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
println("Sampling:")
for i in 1:sample_size
	println(i)
	indexes = sample(L, bundle_size)
	frequencies[indexes] .+= 1
end

#Plot
println("Plotting")
p1=plot(
	tournesol_scores, 
	frequencies/sample_size, 
	seriestype=:scatter, 
	mc=:blue, 
	xlabel="Tournesol score", 
	ylabel="Selection Frequency", 
	label="",
	grid=true,
 	size=(900, 600),
	plot_title="Power = "*string(power)*
		" Bundle size = "*string(bundle_size)*
		" Sample size = "*string(sample_size)
	)

savefig("power_tuning/"*
	"fairness"*
	"power="*string(power)*
	"bundlesize="*string(bundle_size)*
	"_samplesize="*string(sample_size)*
	".png"
	)
