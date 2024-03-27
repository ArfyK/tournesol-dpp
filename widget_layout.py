import random

import requests
import pandas as pd
import ipywidgets as widgets

from IPython.display import display

def make_box_for_grid(thumbnail_widget, title, channel, publication_date, duration, view_count):
    h1 = widgets.HTML(value=title)
    h2 = widgets.HTML(value=channel)
    h3 = widgets.HTML(value=duration + " - " + publication_date)
    h4 = widgets.HTML(value="Views: " + view_count)
    
    
    boxb = widgets.Box()
    boxb.layout = widgets.Layout()
    boxb.children = [thumbnail_widget]

    # Compose into a vertical box
    vb = widgets.VBox()
    vb.layout.align_items = "center"
    vb.children = [boxb, h1, h2, h3, h4]
    return vb


def increment_preferences_results(button, preferences_results_series, bundle_type):
    preferences_results_series[bundle_type] += 1


def download_thumbnails(id_series, path):
    for video_id in id_series:
        thumbnail_url = "https://i.ytimg.com/vi/" + video_id + "/mqdefault.jpg"
        response = requests.get(thumbnail_url)
        open(path + video_id + ".jpg", "wb").write(response.content)


def bundle_hbox(sample_df, preferences_results_series, bundle_type):
    pd.set_option('display.max_colwidth', 10000)
    boxes = []
    for video_id in sample_df["video"]:
        video_title = sample_df.loc[sample_df["video"] == video_id, "title"].to_string(
            index=False, max_rows=1000
        )
        video_channel = sample_df.loc[
            sample_df["video"] == video_id, "channel"
        ].to_string(index=False)

        duration = sample_df.loc[
            sample_df["video"] == video_id, "duration"
        ].to_string(index=False)

        view_count = sample_df.loc[
            sample_df["video"] == video_id, "view_count"
        ].to_string(index=False)

        try:
            publication_date = sample_df.loc[
                sample_df["video"] == video_id, "publication_date"
            ].to_string(index=False).split('T')[0]
        except TypeError:
            publication_date = ""

        file = open("thumbnails/" + video_id + ".jpg", "rb")
        image = widgets.Image(value=file.read())
        image.layout.object_fit = "contain"

        boxes.append(make_box_for_grid(image, video_title, video_channel, publication_date, duration, view_count))

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
