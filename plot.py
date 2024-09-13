import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

colors = {
    'zzz': 'tab:green',
    'httpz': 'tab:purple',
    'zap': 'tab:orange',
    'go': 'tab:blue',
    'fasthttp': 'tab:red',
    'bun': 'tab:pink',
    'axum': 'tab:brown'
}

def plot_requests(csv_path, x_label, y_label, title, out_path):
    df = pd.read_csv(csv_path, index_col=0)


    num_points = len(df)
    num_columns = len(df.columns)

    for i, column in enumerate(df.columns):
        line_color = colors.get(column, 'gray')
        plt.plot(df.index, df[column], marker='o', label=column, color=line_color)

    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.title(title, loc="left")
    plt.grid(True)

    plt.legend()
    plt.savefig(out_path, bbox_inches='tight')
    plt.close()

def plot_memory(csv_path, x_label, y_label, title, out_path):
    df = pd.read_csv(csv_path)

    bar_colors = [colors.get(server, 'gray') for server in df['server']]

    for i, server in enumerate(df['server']):
        bar_color = colors.get(server, 'gray')
        plt.bar(server, df['memory'][i], label=server, color=bar_color)

    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.title(title, loc="left")
    plt.grid(True)

    plt.legend()
    plt.savefig(out_path, bbox_inches='tight')
    plt.close()


plot_requests("./result/request.csv", "Connections", "Requests per Second", "RPS vs Connections Benchmark", "result/req_per_sec.png")
plot_memory("./result/memory.csv", "Peak Memory (kB)", "Implementation", "Peak Memory vs Implementation", "result/peak_memory.png")
