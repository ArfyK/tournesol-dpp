using LinearAlgebra
using Dates

using DataFrames
using CSV

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

#Quality Model
function get_age_in_days(date::AbstractString, ref_date::Date)::Int
	return max((ref_date - Date(date[1:10], dateformat"yyyy-mm-dd")).value, 1)
	end

function compute_qualities(
			   tournesol_scores_power::Number,
			   criteria_coefficient::Number, 
			   recency_coefficient::Number, 
			   tournesol_scores::Array{Float64, 1}, 
			   criteria_scores::Array{Float64, 2}, 
			   ages_in_day::Array{Int64, 1}
			   )::Array{Float64, 1}
	return tournesol_scores.^tournesol_scores_power + criteria_coefficient*vec(sum(max.(criteria_scores, 0), dims=2)) + recency_coefficient./ages_in_day
	end

ref_date = Date("2023-09-19", dateformat"yyyy-mm-dd")

#Data set up
df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))

tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))

criteria_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

ages_in_days = get_age_in_days.(df[:, :publication_date], ref_date)

coefficients = DataFrame(CSV.File("quality_function_coefficient.csv"))
tournesol_scores_powers = coefficients[:,:tournesol_scores_power]
criteria_coefficients = coefficients[:,:criteria_coefficient]
recency_coefficients = coefficients[:,:recency_coefficient]

qualities = compute_qualities(
			      tournesol_scores_powers[1],
			      criteria_coefficients[1],
			      recency_coefficients[1],
			      tournesol_scores,
			      criteria_scores,
			      ages_in_days
			      )
#Norm each line of criteria score
criteria_scores_norms = sqrt.(sum(abs2, criteria_scores, dims=2)) 
normed_criteria_scores = criteria_scores
for i in 1:size(criteria_scores)[1]
	if criteria_scores_norms[i] > 0.0
		normed_criteria_scores[i,:] /= criteria_scores_norms[i]
	end
end

X = Diagonal(qualities)*normed_criteria_scores

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
