import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def plot_benchmarks(csv_path, x_label, y_label, title, out_path):
    df = pd.read_csv(csv_path, index_col=0)

    num_points = len(df)
    num_columns = len(df.columns)

    for i, column in enumerate(df.columns):
        plt.plot(df.index, df[column], marker='o', label=column)

    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.title(title, loc="left")
    plt.grid(True)

    plt.legend()
    plt.savefig(out_path, bbox_inches='tight')

plot_benchmarks("./result/benchmarks.csv", "Connections", "Requests per Second", "RPS vs Connections Benchmark", "result/rps_conn.png")
