using Statistics
using LinearAlgebra
using Dates

using DataFrames
using CSV
using Plots

using Determinantal 

include("utils.jl")

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
println("Setting up the dataset")
df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))

criteria_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))

ref_date = Date("2023-09-19", dateformat"yyyy-mm-dd")#one day older than the database
ages_in_days = get_age_in_days.(df[:, :publication_date], ref_date)

#results = DataFrame(CSV.File("recency_tuning/filtered_results_discount_[0.001,100.0]_caracteristic_times_[1.0,5000.0]_tournesol_scores_powers_[1.0,5.0].csv"))
results = DataFrame(CSV.File("recency_tuning/filtered_results_discount_[0.0,5.0]_caracteristic_times_[1.0,5000.0]_tournesol_scores_powers_[1.0,5.0].csv"))

#Test parameters
sample_size = 100000
bundle_size = 9
result_rank = 1
(discount, caracteristic_time, power) = sort(results, :prop_top_20_month, rev=true)[result_rank,[:discount, :caracteristic_time, :power]]

#Build the model
println("Building the model")
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
frequencies = zeros(size(tournesol_scores))
for i in 1:sample_size
	println(i)
	indexes = sample(L, bundle_size)
	frequencies[indexes] .+= 1
end

#Plot
println("Plotting")
p1=plot(
	tournesol_scores, 
	frequencies/(sample_size*bundle_size), 
	seriestype=:scatter, 
	mc=:blue, 
	xlabel="Tournesol score", 
	ylabel="Selection Frequency", 
	label="",
	grid=true,
 	size=(900, 600),
)
p2=plot(
	ages_in_days, 
	frequencies/(sample_size*bundle_size), 
	seriestype=:scatter, 
	mc=:green, 
	xlabel="Ages in days", 
	ylabel="Selection Frequency", 
	label="",
	grid=true,
 	size=(900, 600),
)

plot(p1, 
     p2, 
     layout=(1,2), 
     grid=true,
     size=(1000, 660),
     plot_title="Discount = "*string(discount)*
		" tau = "*string(caracteristic_time)*
		" Power = "*string(power)*
		" Bundle size = "*string(bundle_size)*
		" Sample size = "*string(sample_size),
     plot_titlefontsize=9
)

savefig("recency_tuning/"*
	"fairness"*
	"discount="*string(discount)*
	"caracteristic_time="*string(caracteristic_time)*
	"power="*string(power)*
	"bundlesize="*string(bundle_size)*
	"_samplesize="*string(sample_size)*
	".png"
)

