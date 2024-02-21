import requests
import sys
import datetime

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

from dppy.finite_dpps import FiniteDPP

from utils import get_age_in_days, CRITERIA


#### DATA SET UP ####
# df = pd.read_csv(sys.argv[1])
df = pd.read_csv("tournesol_scores_above_20_2023-09-18.csv")

# Model parameters
power = 1.6
discount = 4
caracteristic_time = 205

# Quality model
tournesol_scores = df["tournesol_score"].to_numpy()

ref_date = datetime.datetime(2023, 9, 19, 0, 0)  # one day older than the video database
ages_in_days = df.apply(
    lambda x: get_age_in_days(x, ref_date), axis="columns"
).to_numpy()

qualities = (
    1 + discount * np.exp(-ages_in_days / caracteristic_time)
) * np.apply_along_axis(lambda x: x**power, 0, tournesol_scores)

# Diversity model
criteria_scores = df[CRITERIA[1:]].to_numpy(na_value=0)  # Missing values ?!
criteria_scores_norms = np.sqrt((criteria_scores**2).sum(1))

nonzeros_indices = np.nonzero(criteria_scores_norms)

diversity = criteria_scores
diversity[nonzeros_indices] = (
    (criteria_scores[nonzeros_indices]).transpose()
    / criteria_scores_norms[nonzeros_indices]
).transpose()

# Construct L-Ensemble
X = np.matmul(np.diag(qualities), diversity)
DPP = FiniteDPP("likelihood", **{"L_gram_factor": X})

# Sample
for _ in range(10):
    DPP.sample_exact_k_dpp(size=3)

print(DPP.list_of_samples)
