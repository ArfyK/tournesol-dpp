using LinearAlgebra

using DataFrames
using CSV

using Determinantal 

####Data set up

#the tournesol score is not included in the criteria
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
]

df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))

tournesol_scores = Diagonal(coalesce.(df[:, :tournesol_score], 0))

diversity_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

X = tournesol_scores*diversity_scores

#Set up the L-Ensemble
K = LowRank(X)

L = EllEnsemble(K)

#Sample
n_sample = 1000

bundle_size = 9

results = Array{String, 2}(undef, n_sample, bundle_size)

for i in 1:n_sample
	@show "sample "*string(i)
	results[i,:] = df[sample(L, bundle_size), "uid"]
end

CSV.write("dpp_sampling_bundle_size="*string(bundle_size)*"_n_sample="*string(n_sample)*".csv",DataFrame(results, :auto))

