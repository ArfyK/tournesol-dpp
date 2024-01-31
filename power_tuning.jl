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

ref_date = Date("2023-09-19", dateformat"yyyy-mm-dd")#one day older than the database

tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))

criteria_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

#Construct L-Ensemble
qualities = tournesol_scores.^2
	
#Norm criteria scores
criteria_scores_norms = sqrt.(sum(abs2, criteria_scores, dims=2)) 
normed_criteria_scores = criteria_scores
for i in 1:size(criteria_scores)[1]
	if criteria_scores_norms[i] > 0.0
		normed_criteria_scores[i,:] /= criteria_scores_norms[i]
	end
end

X = Diagonal(qualities)*normed_criteria_scores
K = LowRank(X)
L =  EllEnsemble(K)

identity_matrix = diagm(ones(size(tournesol_scores)))
K =  identity_matrix - inv(L.L + identity_matrix) 

individual_probabilities = diag(K)

#=
plot(
     [ages_in_days tournesol_scores], 
     individual_probabilities, seriestype=:scatter, 
     layout=(2,1), 
     title=["age vs proba" "tournesol_scores vs proba"], 
     legend=false
    )
=#


