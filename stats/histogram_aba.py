import pandas as pd
import matplotlib.pyplot as plt
import sys
import numpy as np
from matplotlib.colors import to_rgba
from scipy import stats

if (len(sys.argv) - 1) % 2 != 0 or len(sys.argv) < 3:
    print("Usage: python script.py <csv1> <title1> [<csv2> <title2> ...]")
    sys.exit(1)

args = sys.argv[1:]
file_title_pairs = list(zip(args[::2], args[1::2]))

plt.figure(figsize=(12, 6))
plt.subplots_adjust(top=0.9, bottom=0.2, left=0.18, right=0.95)

colors = ['red', 'blue', 'lime']

all_filtered_minutes = []
for csv_file, _ in file_title_pairs:
    df = pd.read_csv(csv_file)
    df["minute"] = df["tick"] / 60 / 60
    df["minute"] = df["minute"].round().astype(int)

    df_target = df[(df["type"] == "target_station") & df["data"].str.contains("0")]
    target_iterations = set(df_target["iteration"])

    df_station = df[(df["type"] == "station") & df["data"].str.contains("2")]
    station_iterations = set(df_station["iteration"])

    print(station_iterations)

    valid_iterations = target_iterations.intersection(station_iterations)

    df_filtered = df[df["iteration"].isin(valid_iterations)]

    if not df_filtered.empty:
        all_filtered_minutes.extend(df_filtered["minute"].unique())

print(f"Total unique minutes across all files: {len(set(all_filtered_minutes))}")

actual_min = max(0, np.min(all_filtered_minutes) - 1)
actual_max = np.max(all_filtered_minutes) + 1


for i, (csv_file, title) in enumerate(file_title_pairs):
    df = pd.read_csv(csv_file)
    df["minute"] = df["tick"] / 60 / 60
    df["minute"] = df["minute"].round().astype(int)

    df_target = df[(df["type"] == "target_station") & df["data"].str.contains("0")]
    target_iterations = set(df_target["iteration"])

    df_station = df[(df["type"] == "station") & df["data"].str.contains("2")]
    station_iterations = set(df_station["iteration"])

    valid_iterations = target_iterations.intersection(station_iterations)

    df_filtered = df_target[df_target["iteration"].isin(valid_iterations)]
    color = colors[i % len(colors)]

    if not df_filtered.empty:
        minutes = df_filtered["minute"].values

        if len(minutes) > 1:
            data_min = np.min(minutes)
            data_max = np.max(minutes)

            x = np.linspace(data_min, data_max, 1000)

            kde = stats.gaussian_kde(minutes)
            y = kde(x)

            plt.plot(x, y, label=f"{title}", color=color, linewidth=2)

            plt.fill_between(x, y, alpha=0.3, color=color)
    else:
        plt.plot([], [], label=f"{title}", color=color)

plt.xlabel("Tijd (minuten)", fontsize=60, labelpad=15)
plt.ylabel("Distributie simulaties", fontsize=60, labelpad=15)
plt.grid(True, linestyle='--', alpha=0.7)
plt.xlim(0, actual_max)
plt.ylim(0, 0.4)
plt.legend(fontsize=60)
plt.xticks(fontsize=50)
plt.yticks(fontsize=50)

plt.show()