import pandas
import requests


def build_dataset(collective_criteria_scores, tournesol_score_threshold=20):
    dataset = collective_criteria_scores.pivot(index="video", columns="criteria", values="score")
    # select videos with a tournesol score above threshold
    dataset = dataset.loc[
        dataset["largely_recommended"] >= tournesol_score_threshold
    ]

    # request videos information to the youtube API
    key = "AIzaSyB3wHO0cDMq77AkKEChHgrNSbVuVfbugUc"
    url = (
        "https://youtube.googleapis.com/youtube/v3/videos?"
        +"part=snippet"
    )
    for video_id in dataset.index:
        url += "&id=" + video_id
    url += "&key="+key     
    r = requests.get(url)

    # add the publication dates to the dataset
    dataset["publication_date"] = None
    try:
        for item in r.json()["items"]:
            dataset.loc[dataset.index == item["id"], "publication_date"] = item["snippet"][
                "publishedAt"
            ]
    except:
        pass
    return dataset, r
