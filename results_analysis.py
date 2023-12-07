import sys

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

#### DATA SET UP ####
df = pd.read_csv(sys.argv[1])

results = pd.read_csv(sys.argv[2])
n_sample, bundle_size = results.shape

### Plots

# Selection frequencies
selection_frequencies = pd.DataFrame(columns=["rank", "uid", "frequency"])

selection_frequencies["uid"] = list(
    df.sort_values(by="largely_recommended", ascending=False)["uid"]
)
selection_frequencies["rank"] = range(1, df.shape[0] + 1)
selection_frequencies["frequency"] = np.zeros(df.shape[0])


def compute_occurences(selection_frequencies_dataFrame, uid_series):
    selection_frequencies_dataFrame.loc[
        selection_frequencies_dataFrame["uid"].isin(uid_series),
        "frequency",
    ] = (
        selection_frequencies_dataFrame.loc[
            selection_frequencies_dataFrame["uid"].isin(uid_series),
            "frequency",
        ]
        + 1
    )


results.apply(lambda x: compute_occurences(selection_frequencies, x), axis=1)
selection_frequencies["frequency"] = selection_frequencies["frequency"] / n_sample

selection_frequencies.to_csv(
    "selection_frequencies"
    + "_n_sample="
    + str(n_sample)
    + "_bundle_size="
    + str(bundle_size)
    + ".csv"
)

f, axs = plt.subplots(1, 3, figsize=(13, 7))

sns.barplot(data=selection_frequencies, x="rank", y="frequency", ax=axs[0])

axs[0].set_xticks([], minor=True)
axs[0].set_xticks(list(range(0, 2000, 500)))
axs[0].set_title("Selection frequencies of DPP")

# Top 5%
quantile_95 = df["tournesol_score"].quantile(0.95)


def count_videos_within_threshold(uids_list, dataFrame, quantile, above=True):
    if above:
        # returns how many videos from the uids_list have a tournesol_score above the quantile
        return (
            (dataFrame["uid"].isin(uids_list))
            & (dataFrame["tournesol_score"] >= quantile)
        ).sum()
    else:
        # returns how many videos from the uids_list have a tournesol_score below the quantile
        return (
            (
                dataFrame["uid"].isin(uids_list) & dataFrame["tournesol_score"]
                <= quantile
            )
        ).sum()


results["top_5%"] = results.apply(
    lambda x: count_videos_within_threshold(x, df, quantile_95, above=True), axis=1
)

sns.boxplot(data=results, x="top_5%", ax=axs[1])

axs[1].set_title(
    "Videos from the top 5%" + " | Total: " + str(int(results["top_5%"].sum()))
)

# Bottom 50%
quantile_50 = df["tournesol_score"].quantile(0.5)

results["bottom_50%"] = results.apply(
    lambda x: count_videos_within_threshold(x, df, quantile_95, above=True), axis=1
)

sns.boxplot(data=results, x="bottom_50%", ax=axs[2])

axs[2].set_title(
    "Videos from the bottom 50%" + " | Total: " + str(int(results["bottom_50%"].sum()))
)

f.suptitle("From " + str(n_sample) + " samples of " + str(bundle_size) + " videos.")

plt.subplots_adjust(
    left=0.052, bottom=0.09, right=0.998, top=0.907, wspace=0.055, hspace=0.34
)
plt.show()
plt.savefig(
    fname="dpp_sampling"
    + "_n_sample="
    + str(n_sample)
    + "_bundle_size="
    + str(bundle_size)
    + ".png"
)
