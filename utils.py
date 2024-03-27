import io
import datetime
import random

import requests
import numpy as np
import pandas as pd
import ipywidgets as widgets

from dppy.finite_dpps import FiniteDPP
from IPython.display import display


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


# Widget layout functions


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


def increment_preferences_results(button, preferences_results_series, bundle_type):
    preferences_results_series[bundle_type] += 1


def download_thumbnails(id_series, path):
    for video_id in id_series:
        thumbnail_url = "https://i.ytimg.com/vi/" + video_id + "/mqdefault.jpg"
        response = requests.get(thumbnail_url)
        open(path + video_id + ".jpg", "wb").write(response.content)


def bundle_hbox(sample_df, preferences_results_series, bundle_type):
    boxes = []
    for video_id in sample_df["video"]:
        video_title = sample_df.loc[sample_df["video"] == video_id, "title"].to_string(
            index=False
        )
        video_channel = sample_df.loc[
            sample_df["video"] == video_id, "channel"
        ].to_string(index=False)

        file = open("thumbnails/" + video_id + ".jpg", "rb")
        image = widgets.Image(value=file.read())
        image.layout.object_fit = "contain"

        boxes.append(make_box_for_grid(image, video_title, video_channel))

    button = widgets.Button(description="Preferred bundle")
    button.on_click(
        lambda button: increment_preferences_results(
            button, preferences_results_series, bundle_type
        )
    )
    boxes.append(button)

    hbox_layout = widgets.Layout()
    hbox_layout.width = "100%"
    hbox_layout.justify_content = "space-around"

    hb = widgets.HBox()
    hb.layout = hbox_layout
    hb.children = boxes
    return hb


def construct_bundles_widget(
    df,
    dpp,
    preferences_results_series,
    recent_videos_to_sample,
    old_videos_to_sample,
    bundle_size,
):
    # Uniform sampling
    recent_videos_sample = df.loc[df["age_in_days"] <= 21].sample(
        n=recent_videos_to_sample, replace=False
    )
    old_videos_sample = df.loc[df["age_in_days"] > 21].sample(
        n=old_videos_to_sample, replace=False
    )

    uniform_sample = pd.concat([recent_videos_sample, old_videos_sample])

    # DPP sampling
    dpp_sample = df.iloc[dpp.sample_exact_k_dpp(size=bundle_size)]

    # Download thumbnails in the thumbnails directory
    download_thumbnails(uniform_sample["video"], "thumbnails/")
    download_thumbnails(dpp_sample["video"], "thumbnails/")

    # Widget layout
    uniform_hb = bundle_hbox(uniform_sample, preferences_results_series, "uniform")
    dpp_hb = bundle_hbox(dpp_sample, preferences_results_series, "dpp")

    # Randomly compose into a vertical box
    vb = widgets.VBox()
    vb.layout.align_items = "center"
    if bool(random.getrandbits(1)):
        vb.children = [dpp_hb, uniform_hb]
    else:
        vb.children = [uniform_hb, dpp_hb]

    display(vb)
