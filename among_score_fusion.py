from __future__ import print_function
import sys
from sklearn.linear_model import LogisticRegression

files = [open(fname) for fname in sys.argv[1:]]

training_X = []
training_Y = []
testing_X = []
testing_docs = []
def valid(lines):
    assert(len(set([line[0] for line in lines])) == 1)
    assert(len(set([line[1] for line in lines])) == 1)
    assert(len(set([line[2] for line in lines])) == 1)

def is_test(lines):
    return lines[0][1] == 'Ham' or lines[0][1] == 'Spam'

try:
    while True:
        lines = [next(file).split() for file in files]
        valid(lines)
        if is_test(lines):
            testing_X.append(
                ([float(line[3]) for line in lines])
            )
            testing_docs.append(lines[0][0])
            break
        training_X.append(
            ([float(line[3]) for line in lines])
        )
        training_Y.append(lines[0][1])
except StopIteration:
    pass

classifier = LogisticRegression(class_weight="balanced", n_jobs=-1)
classifier.fit(training_X, training_Y)

try:
    while True:
        lines = [next(file).split() for file in files]
        valid(lines)
        testing_X.append(
            ([float(line[3]) for line in lines])
        )
        testing_docs.append(lines[0][0])
except StopIteration:
    pass

map(lambda x: x.close(), files)
idx = list(classifier.classes_).index('spam')
for doc, score in zip(testing_docs, classifier.predict_proba(testing_X)):
    print('%s %.5f' % (doc, score[idx]))
