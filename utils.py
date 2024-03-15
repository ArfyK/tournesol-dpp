import numpy as np
import datetime

import ipywidgets as widgets

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
