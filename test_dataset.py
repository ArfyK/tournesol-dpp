import io
import zipfile

import requests
import pandas as pd

import dataset

response = requests.get("https://api.tournesol.app/exports/all")
zip_file = zipfile.ZipFile(io.BytesIO(response.content))
collective_scores = pd.read_csv(zip_file.open("collective_criteria_scores.csv"))

df = dataset.build_dataset(collective_scores)

print(df[["title", "channel", "publication_date"]])
