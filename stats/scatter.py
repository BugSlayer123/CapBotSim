import csv
import sys
import matplotlib.pyplot as plt
from collections import defaultdict
import math

def process_csv(path):
    data_per_minute = defaultdict(list)

    with open(path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            tick = int(row['tick'])
            data_items = row['data'].split(',')
            print(data_items)
            minute = math.floor(tick / 3600)
            data_per_minute[minute].append(len(data_items))

    sorted_minutes = sorted(data_per_minute.keys())
    avg_data_sizes = [sum(sizes) / len(sizes) for minute in sorted_minutes for sizes in [data_per_minute[minute]]]

    return sorted_minutes, avg_data_sizes

def main():
    args = sys.argv[1:]
    if len(args) < 2 or len(args) % 2 != 0:
        print("Usage: python scatter.py <csv1> <label1> [<csv2> <label2> ...]")
        sys.exit(1)

    for i in range(0, len(args), 2):
        csv_path = args[i]
        label = args[i + 1]
        minutes, averages = process_csv(csv_path)
        plt.scatter(minutes, averages, label=label)

    plt.title('Cumulatieve data groei per minuut')
    plt.xlabel('Tijd (minutes)')
    plt.ylabel('Gemiddeld aantal data items bij doel')
    plt.legend()
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
