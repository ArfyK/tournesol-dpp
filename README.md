**Table of contents**
  - Introducton
  - How to use `power_tuning.jl`
  - Results analysis

## Introduction
Enforcing diversity in recommended video bundles using Determinantal Point Processes.

Quality model : q=tournesol_score^power
Diversity model : normed criteria vector c

Thus each video is represented by the vector qc.

Tests are performed on the dataset `tournesol_scores_above_20_2023-09-18.csv`.

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
  1) in average videos should appear in about 0.6% of bundles;
  2) videos from the top 5% should appear in about 3% of bundles, that is (?) each bundle should contain 25% of videos from the top 5%;
  3) videos of the top 5% should appear 10 times as much in bundles as the lower 50%.

