import numpy as np
import datetime

import ipywidgets as widgets

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

    ref_date = datetime.datetime(
        2023, 9, 19, 0, 0
    )  # one day older than the video database
    ages_in_days = df["age_in_days"].to_numpy(na_value=df["age_in_days"].max())

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
    return FiniteDPP("likelihood", **{"L_gram_factor": X})


def make_box_for_grid(thumbnail_widget, title, channel):
    h1 = widgets.HTML(value=title)
    h2 = widgets.HTML(value=channel)

    boxb = widgets.Box()
    boxb.layout = widgets.Layout()
    boxb.children = [thumbnail_widget]

    # Compose into a vertical box
    vb = widgets.VBox()
    vb.layout.align_items = "center"
    vb.children = [boxb, h1, h2]
    return vb
