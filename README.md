**Table of contents**
  - Introduction
  - Without recency
  - With recency

# Introduction
Enforcing diversity in recommended video bundles using Determinantal Point Processes.

Tests are performed on the dataset `tournesol_scores_above_20_2023-09-18.csv`.

# Without recency 

## Model

Quality model : q=tournesol_score^power

Diversity model : normed criteria vector c

Thus each video is represented by the vector qc.

This model has one parameter which is tuned with the script `power_tuning.jl`.

## How to use `power_tuning.jl`

First set the tests parameters in the script:
  - the number sample `sample_size`;
  - the bundle size `bundle_size`;
  - the powers to be tested `tournesol_scores_powers`.

Run the script:
`/path/to/julia power_tuning.jl` 

This will create the file `/power_tuning/bundlesize=<bundle_size>_samplesize=<sample_size>.png` gathering plots.

## Results analysis

Targets :
  1) videos from the top 5% should appear in about 3% of bundles, that is (?) each bundle should contain 25% of videos from the top 5%;
  2) videos of the top 5% should appear 10 times as much in bundles as the lower 50%.
  3) no video should be selected more than 20% of the time.

On `/power_tuning/bundlesize=<bundle_size>_samplesize=<sample_size>.png` we observe that :
  - target 2 is always satisfied (cf graphs (1, 1) and (1, 2));
  - the power should be below 5 to satisfy target 3 (cf graph (2,1)); 
  - the power should be above around 2 to satisfy target 1.

# With recency 

## Model

Quality model : q=tournesol_score^power*(1 + discount*exp(-age/caracteristic_time))

Diversity model : normed criteria vector c

Thus each video is represented by the vector qc.

This model has three parametere which can be tuned with the script `recency_tuning.jl`.

## How to use `recency_tuning.jl`

Disclaimer : some parts of the script are unnecessarily complex because I initially misunderstood how to use `DataFrames.jl`.

First set the tests parameters in the script:
  - the `sample_size`;
  - the `bundle_size`;
  - the `tournesol_scores_powers` to be tested;
  - the `discount_coefficients` to be tested;
  - the `caracteristic_times` to be tested;
  - the `selection_frequency_limit`, the `minimum_top_20_proportion` and the `maximum_top_20_proportion` values that will filter the results.

Run the script:
`/path/to/julia recency_tuning.jl` 

This will create two files in the recency_tuning directory:
  - a csv file containing the results;
  - a png gathering scatter plots about the proportion of videos from the top 20 of last month versus the maximum selection frequency and parameter values.

## How to get further information about the results

Once the tests are run you can get further information in the julia REPL by running:

`using DataFrames`

`using CSV`

`df = DataFrame(CSV.File(<results_file>.csv))`

sort(df, :prop_top_20_month, rev=true)[1:20,[:discount, :caracteristic_time, :power, :prop_top_20_month]]`

This will display 20 parameter sets giving the highest proportion of videos from the top 20 of last month per bundle.

To plot details about those parameter sets you can run:

`include("utils.jl")`

`plot_parameters_sets_details(df, sort(df, :prop_top_20_month, rev=true)[1:10,[:discount, :caracteristic_time]])`

This will create 1 plot per parameter set in the recency_tuning directory.

## Results analysis

Targets :
  1) videos from the top 5% should appear in about 3% of bundles, that is (?) each bundle should contain 25% of videos from the top 5%;
  2) videos of the top 5% should appear 10 times as much in bundles as the lower 50%.
  3) no video should be selected more than 20% of the time.
  4) videos from the top 20 of the month should appear in about 20% (10% - 30%) of the bundles.

### discount in [1e-3, 100], caracteristic time in [1, 5000], power in [1, 5]

Observations:
  - the higher top 20 proportion is about 18%;
  - the discount value does not seem to impact it.

### discount in [1e-3, 100], caracteristic time in [1, 5000], power in [5, 10]

Observation:
  - the higher top 20 proportion is about 11%;


