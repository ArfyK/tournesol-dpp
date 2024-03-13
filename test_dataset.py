import pandas as pd

import dataset

collective_criteria_scores = pd.read_csv(
    "tournesol_dataset/collective_criteria_scores.csv"
)

df = dataset.build_dataset(collective_criteria_scores)

print(df["publication_date"])
