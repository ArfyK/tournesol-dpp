import pandas as pd

import dataset

collective_criteria_scores = pd.read_csv('tournesol_dataset/collective_criteria_scores.csv')

video_ids = collective_criteria_scores['video'].unique()
n_videos = 53 
small_collective_criteria_scores = collective_criteria_scores.loc[collective_criteria_scores['video'].isin(video_ids[:n_videos])]

df, r = dataset.build_dataset(small_collective_criteria_scores, tournesol_score_threshold=-100)

print(r.json())
