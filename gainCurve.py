import os
import argparse
import colorsys
import matplotlib.pyplot as plt

def plot(fname, color, label):
    x_vals = [0]
    y_vals = [0]
    with open(fname) as f:
        for line in f:
            _, score = line.strip().split()
            score = int(score)
            y_vals.append(y_vals[-1] + score)
            x_vals.append(x_vals[-1] + 1)
    plt.plot(x_vals, y_vals, color=color, label=label)

def get_random_color(i, n):
    hue = (360//n*i)/360.0
    sat = 0.5
    light = 0.5
    r,g,b = colorsys.hls_to_rgb(hue, light, sat)
    return '#%02x%02x%02x' % (int(r*255), int(g*255), int(b*255))

if __name__ == '__main__':
    PARSER = argparse.ArgumentParser(description='Plot gain curves from CAL record list')
    PARSER.add_argument('files', help='Path of record list(<topic>.record.list) file', nargs='+')
    PARSER.add_argument('--log-scale', help='Plot effort in log scale', default=False, action='store_true')
    CLI = PARSER.parse_args()
    for idx, fname in enumerate(CLI.files):
        plot(fname, get_random_color(idx, len(CLI.files)), "file-%d" % idx)
    plt.xlabel("effort")
    plt.ylabel("documents")
    if CLI.log_scale:
        plt.xscale('log')
    ax = plt.subplot(111)
    box = ax.get_position()
    ax.set_position([box.x0, box.y0 + box.height * 0.1,
                 box.width, box.height * 0.9])
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.05),
          fancybox=True, shadow=True, ncol=5)
    plt.show()
