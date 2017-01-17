# BMI local Implementation

## Installation

1. `git clone https://github.com/HTAustin/CAL.git`
2. Intall Sofia-ML package: https://code.google.com/archive/p/sofia-ml/
3. Make the kisssdb indexer. `cd CAL && make`
4. Change the path for Sofia-ML in doAll_Baseline
```
SOFIA="/the/path/to/sofia-ml-read-only/src/sofia-ml"
```

## Usage

1. Run CAL Auto TAR: `bash doAll_Baseline`
2. Configure behaviour through environment variables
```
MODE            - default tfidf. Valid values: 4gram, tfidf
MAXTHREADS      - number of threads. Default: 4
SOFIA           - path to sofia ml binary. Default: ./sofia-ml/src/sofia-ml
CORP            - corpus to use. Default: oldreut
CACHE           - if set, enable caching of corpus specific pre computations. Default not set.

eg.
$ MODE=4gram MAXTHREADS=16 SOFIA=/home/nghelani/sofia-ml/sofia-ml CORP=aquaint bash doAll_Baseline
```
3. Important files assumed by the script
```
Corpus/<CORP>.tgz                       - Corpus
judgement/<CORP>.topic.stemming.txt     - Topics separated by newline (each line is "<topic_id>:<query>")
judgement/qrels.<JUDGECLASS>.list       - Relevance judgements for topics (each line is "<topic> 0 <doc> <score>")
```
4. The output of BMI are stored in `result/` folder. 
5. The gain curve can be plotted by analyzing `result/baseline/<corp>/<topic>/<topic>.record.list`
6. Plot gain curves with `gainCurve.py` (see `python2 gainCurve.py -h`)

## Speedup Tips

1. Comment out the `./dofast` line if you already completed fine the last time
2. If using qrels for assessment, consider quitting the iterations when you have found the desired number of relevant documents (See the sample snippet)
```bash
    NUM_REL=$(cat rel.$TOPIC.fil | sort | uniq | wc -l)
    TOT_REL=$(grep "^$TOPIC.*[1-9]$" ../judgement/qrels.$JUDGECLASS.list | cut -d' ' -f3 | sort | uniq | wc -l)
    if [ $NUM_REL -eq $TOT_REL ]; then
        break
    fi
```
3. Lower the number of iterations. The default number of iterations (=100) might be too high for your purpose.

## Contribute

Please feel free to open issues and report bugs.

## License

[![GNU GPL v3.0](http://www.gnu.org/graphics/gplv3-127x51.png)](http://www.gnu.org/licenses/gpl.html)
