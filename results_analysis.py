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

f, axs = plt.subplots(1, 3)

sns.barplot(data=selection_frequencies, x="rank", y="frequency", ax=axs[0])

ax[0].set_xticks([], minor=True)
ax[0].set_xticks(list(range(0, 2000, 500)))
ax[0].set_title("Selection frequencies of DPP")

plt.subplots_adjust(
    left=0.04, bottom=0.043, right=0.998, top=0.907, wspace=0.055, hspace=0.34
)
plt.show()
