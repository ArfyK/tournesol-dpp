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

### Quality Model
function quality(
		 age_in_days::Number,
		 tournesol_score::Number;
		 tournesol_score_power::Number,
		 age_scoring::Function
		 )::Number
	return tournesol_score^tournesol_score_power+age_scoring(age_in_days)
	end

function age_scoring(f::Function;
		     coefficient::Number=1,
		     center::Number=0,
		     scale::Number=1)::Function
	return x -> coefficient*f((x-center)/scale)
        end
### L-ensemble construction

function get_age_in_days(date::AbstractString, ref_date::Date)::Int
	return max((ref_date - Date(date[1:10], dateformat"yyyy-mm-dd")).value, 1)
	end

function construct_L_Ensemble(
			     tournesol_scores::Vector,
			     criteria_scores::Matrix,
			     ages_in_days::Vector;
			     quality_function::Function=quality,
			     quality_function_kwargs...)::EllEnsemble{Float64}
	qualities = quality_function(tournesol_scores, ages_in_days;quality_function_kwargs...)

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
	return EllEnsemble(K)
	end

