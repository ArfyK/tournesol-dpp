import datetime

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
    return max(
        (
            ref_date
            - datetime.datetime.strptime(
                video_series["publication_date"].split("T")[0], "%Y-%m-%d"
            )
        ).days,
        1,
    )  # remove the time part of the datetime with the split because some entries only have the date part.


