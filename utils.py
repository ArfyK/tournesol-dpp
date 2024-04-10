import io
import datetime

import numpy as np
import pandas as pd

from dppy.finite_dpps import FiniteDPP



CRITERIA = [
    "largely_recommended",
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


def get_age_in_days(video_series, ref_date):
    # return 1 if the video is less than a day old
    try:
        return max(
            (
                ref_date
                - datetime.datetime.strptime(
                    video_series["publication_date"], "%Y-%m-%dT%H:%M:%SZ"
                )
            ).days,
            1,
        )
    except TypeError:
        return np.nan


def construct_L_Ensemble(df, power, discount, caracteristic_time):
    # Quality model
    tournesol_scores = df["largely_recommended"].to_numpy()

    ages_in_days = df["age_in_days"].to_numpy(na_value=df["age_in_days"].max())

    qualities = (
        1 + discount * np.exp(-ages_in_days / caracteristic_time)
    ) * np.apply_along_axis(lambda x: x**power, 0, tournesol_scores)

    # Diversity model
    criteria_scores = df[CRITERIA[1:]].to_numpy(na_value=0)  # Missing values ?!
    criteria_scores += 2*np.abs(criteria_scores.min(axis=0)) #ensures we only have positive scores

    log_video_statistics = np.log(df[['age_in_days', 'view_count']].to_numpy(na_value=1))
    scale = criteria_scores.max(axis=0).mean()
    scaled_minimum = criteria_scores.min(axis=0).mean()
    scaled_log_video_statistics = scale*((log_video_statistics - log_video_statistics.min(axis=0))/(log_video_statistics.max(axis=0) - log_video_statistics.min(axis=0))) + scaled_minimum

    features_vectors = np.concatenate((criteria_scores, scaled_log_video_statistics),axis=1)
    features_vectors_norms = np.sqrt((features_vectors**2).sum(1))
    nonzeros_indices = np.nonzero(features_vectors_norms)

    diversity = features_vectors
    diversity[nonzeros_indices] = (
        (features_vectors[nonzeros_indices]).transpose()
        / features_vectors_norms[nonzeros_indices]
    ).transpose()

    # Construct L-Ensemble
    X = np.matmul(diversity.transpose(), np.diag(qualities))
    return FiniteDPP("likelihood", **{"L_gram_factor": X})
