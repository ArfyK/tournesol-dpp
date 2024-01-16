using DataFrames
using CSV
using Plots

include("utils.jl")


#Data set up

df = DataFrame(CSV.File("tournesol_scores_above_20_2023-09-18.csv"))

ref_date = Date("2023-09-19", dateformat"yyyy-mm-dd")#one day older than the database

tournesol_scores = Vector(coalesce.(df[:, :tournesol_score], 0))

criteria_scores = Matrix(coalesce.(df[:, CRITERIA], 0))

ages_in_days = get_age_in_days.(df[:, :publication_date], ref_date)

quality_model_parameters = Dict(
				:tournesol_score_power=>5,
				:age_scoring=>age_scoring(exp)
				)

L = construct_L_Ensemble(tournesol_scores,
			 criteria_scores,
			 ages_in_days,
			 quality_function_kwargs=quality_model_parameters
			 )

individual_probabilities = diag(L)

plot(
     [ages_in_days tournesol_scores], 
     individual_probabilities, seriestype=:scatter, 
     layout=(2,1), 
     title=["age vs proba" "tournesol_scores vs proba"], 
     legend=false
    )


