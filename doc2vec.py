"""
Converts document tf idf vectors to doc2vec using w2v embeddings
"""
import sys
import numpy as np
from tqdm import tqdm

def load_bin_vec(fname):
    """
    Loads 300x1 word vecs from Google (Mikolov) word2vec
    """
    # w2vDict = {}
    word_vecs = {}
    lineCnt = 0
    with open(fname, "rb") as f:
        header = f.readline()
        vocab_size, layer1_size = map(int, header.split())
        print "w2v vocab size is " + str(vocab_size)
        binary_len = np.dtype('float32').itemsize * layer1_size
        for _ in xrange(vocab_size):
            word = []
            while True:
                ch = f.read(1)
                if ch == ' ':
                    word = ''.join(word)
                    break
                if ch != '\n':
                    word.append(ch)
            word_vecs[word] = np.fromstring(f.read(binary_len), dtype='float32')
    return word_vecs

import pdb
def main():
    svm_fil_fname = sys.argv[1]
    w2v_fname = sys.argv[2]
    dictionary_fname = sys.argv[3]
    out_fname = sys.argv[4]
    w2v_dict = load_bin_vec(w2v_fname)
    dictionary = {}
    with open(dictionary_fname) as f:
        for line in f:
            _id, word = line.strip().split()
            dictionary[_id] = word

    cnt = set()
    with open(out_fname, 'w') as out_f:
        with open(svm_fil_fname) as f:
            for doc_line in tqdm(f):
                features = doc_line.strip().split()
                doc_id = features[0]
                features = features[1:]
                weight_sum = 0.0
                new_features = np.array([0]*300, dtype='float32')
                for feature in features:
                    feature_id, score = feature.split(':')
                    score = float(score)
                    word = dictionary[feature_id]
                    if word in w2v_dict:
                        new_features += w2v_dict[word] * score
                        weight_sum += score
                new_features /= weight_sum
                out_f.write('%s %s\n'
                            % (
                                doc_id, 
                                ' '.join(('%d:%f' % (idx,
                                          score) for (idx, score) 
                                          in enumerate(new_features)))
                            )
                            )


if __name__ == '__main__':
    main()
