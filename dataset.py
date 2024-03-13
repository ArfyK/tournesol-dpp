import pandas
import requests


def build_dataset(collective_criteria_scores, tournesol_score_threshold=20):
    dataset = collective_criteria_scores.pivot(
        index="video", columns="criteria", values="score"
    )
    # select videos with a tournesol score above threshold
    dataset = dataset.loc[dataset["largely_recommended"] >= tournesol_score_threshold]
    dataset["publication_date"] = None
    dataset["title"] = None
    dataset["channel"] = None
    dataset.reset_index(inplace=True)

    # request videos information to the youtube API
    key = "AIzaSyB3wHO0cDMq77AkKEChHgrNSbVuVfbugUc"
    url_prefix = (
        "https://youtube.googleapis.com/youtube/v3/videos?"
        + "part=snippet"
        + "&key="
        + key
    )

    # Split the request in blocks of 50 ids because of the API limitations
    n_videos = dataset.shape[0]
    n_blocks = n_videos // 50
    for i in range(n_blocks + 1):
        url = url_prefix
        if i < n_blocks:  # blocks of 50 ids
            for j in range(0, 50):
                url += (
                    "&id="
                    + dataset.loc[dataset.index == (i * 50 + j), "video"]
                    .to_string(index=False, header=False)
                    .lstrip()
                )
        else:  # last partially filled block
            for j in range(0, n_videos % 50 + 1):  # last partially filled block
                url += (
                    "&id="
                    + dataset.loc[dataset.index == (n_blocks * 50 + j), "video"]
                    .to_string(index=False, header=False)
                    .lstrip()
                )
        r = requests.get(url)
        for item in r.json()["items"]:
            dataset.loc[
                dataset["video"] == item["id"], ["title", "channel", "publication_date"]
            ] = (
                item["snippet"]["title"],
                item["snippet"]["channelTitle"],
                item["snippet"]["publishedAt"],
            )

    return dataset
