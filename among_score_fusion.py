import sys
from sklearn.linear_model import LogisticRegression

files = [open(fname) for fname in sys.argv[1:]]

training = []
testing = []
def valid(lines):
    assert(len(set([line[0] for line in lines])) == 1)
    assert(len(set([line[1] for line in lines])) == 1)
    assert(len(set([line[2] for line in lines])) == 1)

while True:
    lines = [next(file).split() for file in files]
    valid(lines)
    if is_test(lines):
        testing.append(
            (lines[0][0], [float(line[3]) for line in lines])
        )
        break
    training.append(
        (lines[0][1], [float(line[3]) for line in lines])
    )

while True:
    lines = [next(file).split() for file in files]
    valid(lines)
    testing.append(
        (lines[0][0], [float(line[3]) for line in lines])
    )



map(lambda x: x.close(), files)
