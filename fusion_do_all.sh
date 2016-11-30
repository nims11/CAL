#!/bin/bash
#Assume the index has been built
# rm -rf lemurindex
# mkdir lemurindex
# mkdir corpdata
# cd corpdata ; tar xf ../$ZIPF ; cd ../ 
# python clustering/generateLemurIndexXML.py --index=diskindex --raw=~/TREC/Corpus/robust04  --xmloutput=index/disk.xml
# ~/Develop/lemur/bin/IndriBuildIndex index/disk.xml
# rm -rf corpdata


PURPOSE=baseline
JUDGECLASS="aquaint"

#CORPLIST=("robust04_0" "robust04_1" "robust04_2" "robust04_3" "robust04_4" "robust04_5")
#CORPLIST=("FBIS" "FT" "FR" "LA")
CORPLIST=("aquaint")
SOFIA="/home/nghelani/cal-fusion/sofia-ml/sofia-ml"
MAX_THREADS=10

for CORP in "${CORPLIST[@]}"
do
    # if ! [ -e Corpus/"$CORP".tgz ] ; then
    # tar -cvzf Corpus/"$CORP".tgz Corpus/"$CORP"/
    # fi 


    pushd Corpus

    # if [ ! -e "$CORP".svm.fil ] || [ ! -e "$CORP".df ]; then
    # ./dofast "$CORP"
    # fi

    cp "$CORP".df ../"$CORP".df

    cp "$CORP".svm.fil ../"$CORP".svm.fil

    KEYSIZE=$(awk 'BEGIN{a=0}{len = length($1); a=a<len?len:a}END{print a}' "$CORP".svm.fil)
    VALSIZE=$(awk 'BEGIN{a=0}{len = length($0); a=a<len?len:a}END{print a}' "$CORP".svm.fil)
    KEYSIZE=$((KEYSIZE+2))
    VALSIZE=$((VALSIZE+2))
    # echo "Indexing $CORP.svm.fil, keysize = $KEYSIZE, valsize = $VALSIZE"
    # ./indexer "$CORP".svm.fil "$CORP".db $KEYSIZE $VALSIZE || (echo "Error creating db"; exit 1)

    popd

    while IFS='' read -r line || [[ -n $line ]]; do
        IFS=':' read -ra TEXT <<< "$line"

        TOPIC="${TEXT[0]}"
        QUERY="${TEXT[1]}"
        echo "$TOPIC"
        echo "$QUERY"

        rm -rf result/"$PURPOSE"/"$CORP"/"$TOPIC"/
        mkdir -p result/"$PURPOSE"/"$CORP"/
        mkdir -p result/dump/"$PURPOSE"/"$CORP"/

        rm -rf $TOPIC
        mkdir $TOPIC


        echo `wc -l < "$CORP".svm.fil` > N
        pushd $TOPIC 
        for SYS in {1..2}; do
            mkdir $SYS
        done

        echo "$QUERY" > "$TOPIC".seed.doc




        cut -d' ' -f1 ../$CORP.svm.fil | sed -e 's/.*/& &/' | \
            tee docfil | cut -d' ' -f1 | cat -n > docfils



        for SYS in {1..2}; do
            pushd $SYS
            touch rel.$TOPIC.fil

            #cut -f2 docfil | join - $TOPIC.seed.sorted | cut -d' ' -f2 >> rel.$TOPIC.fil

            touch prel.$TOPIC
            rm -rf prevalence.rate
            touch prevalence.rate
            rm -rf rel.rate
            touch rel.rate
            touch $TOPIC.record.list
            popd
        done


        rm -f new[0-9][0-9].$TOPIC tail[0-9][0-9].$TOPIC self*.$TOPIC gold*.$TOPIC
        touch new00.$TOPIC


        NDOCS=`cat docfils | wc -l`
        NDUN=0
        L=1
        R=100
        export LAMBDA=0.0001

        cp $TOPIC.seed.doc ../$TOPIC.seed.doc
        popd

        ./dofeaturesseed $TOPIC.seed.doc $TOPIC $CORP
        pushd $TOPIC
        sed -e 's/[^ ]*/0/' ../$CORP.svm.fil | ../dosplit
        sed -e 's/[^ ]*/1/' svm.$TOPIC.seed.doc.fil > $TOPIC.synthetic.seed


        for x in {0..9} ; do
            for y in {0..9} ; do
                if [ $NDUN -lt $NDOCS ] ; then
                    export N=$x$y
                    echo "GENERATE TRAINING SET"
                    for SYS in {1..2}; do
                        pushd $SYS
                        cp ../$TOPIC.synthetic.seed trainset
                        cut -f2 ../docfils | shuf -n$R | sort |\
                            ../../indexer ../../$CORP.db $KEYSIZE $VALSIZE | sed -e's/[^ ]*/-1/' > trainset1 &
                        (
                        cat ../new[0-9][0-9].$TOPIC | sort > seed
                        cat seed | join - rel.$TOPIC.fil | sed -e 's/^/1 /' > x
                        cat seed | join -v1 - rel.$TOPIC.fil | sort -R | head -50000 | sed -e 's/^/-1 /' >> x
                        cut -d' ' -f2 x | ../../indexer ../../$CORP.db $KEYSIZE $VALSIZE | cut -d' ' -f2- | paste -d' ' <(cut -d' ' -f1 x) - | sort -n > trainset2
                        ) &
                        popd
                    done
                    wait

                    echo "TRAIN!"
                    for SYS in {1..2}; do
                        pushd $SYS
                        (
                        cat trainset1 trainset2 >> trainset
                        rm trainset1 trainset2

                        #Calculate relevant documents prevalence rate in the traning set
                        RELTRAINDOC=`grep -E "^1\b" trainset | wc -l`
                        NOTRELTRAINDOC=`grep -E "^-1\b" trainset | wc -l`
                        PREVALENCERATE=`echo "scale=4; $RELTRAINDOC / ($RELTRAINDOC + $NOTRELTRAINDOC)" | bc`
                        echo $RELTRAINDOC $NOTRELTRAINDOC $PREVALENCERATE >> prevalence.rate

                        $SOFIA --learner_type logreg-pegasos --loop_type roc --lambda $LAMBDA\
                            --iterations 200000 --training_file trainset\
                            --dimensionality 3300000 --model_out svm_model
                        RES=$?
                        echo $RES
                        X=1
                        echo "TEST!"
                        if [ "$RES" -eq "0" ] ; then
                            for z in ../svm.test.* ; do
                                while [ "$(jobs | grep 'Running' | wc -l)" -ge "$MAXTHREADS" ]; do
                                    sleep 1
                                done
                                $SOFIA --test_file $z --dimensionality 3300000\
                                    --model_in svm_model --results_file pout."$(basename $z)" &
                            done
                            if [ $((X%10)) -eq 0 ]; then
                                wait
                            fi
                            X=$((X+1))
                        else
                            rm -f pout.svm.test.*
                            cut -f2 ../docfils | sort -R | cat -n | sort -k2 | sed -e 's/ */-/' > pout.svm.test.1
                        fi
                        wait

                        cut -f1 pout.svm.test.* | ../../fixnum | cat -n | join -o2.2,1.2 -t$'\t' - ../docfils > inlr.out
                        sort seed | join -v2 - inlr.out | sort -rn -k2 | cut -d' ' -f1 > new$N.$TOPIC &
                        awk \
                            'NR==FNR{a[$1]=$2}\
                            NR!=FNR{if($1 in a)\
                            printf("%s judge=%s class=Ham score=%s\n", $1, $2>0?"spam":"ham", $2);}'\
                            "$TOPIC".record.list inlr.out > fusion_training
                        if [[ $(wc -l < "$TOPIC".record.list) > 0 ]]; then
                            awk \
                                'NR==FNR{a[$1]=$2}\
                                NR!=FNR{if($1 in a){}else\
                                printf("%s judge=%s class=Ham score=%s\n", $1, "Ham", $2);}'\
                                "$TOPIC".record.list inlr.out >> fusion_training
                        else
                            awk \
                                '{\
                                printf("%s judge=%s class=Ham score=%s\n", $1, "Ham", $2);}'\
                                inlr.out >> fusion_training
                        fi
                        wait
                        ) &
                        popd
                    done
                    wait

                    # python3 ../fusion.py 1/new$N.$TOPIC 2/new$N.$TOPIC > new$N.$TOPIC
                    ../logmangle 1/fusion_training 2/fusion_training | tr '=' ' ' | cut -d' ' -f1,7 | sort > fused_ranklist
                    sort 1/seed | join -v2 - fused_ranklist | sort -rn -k2 > x
                    mv x fused_ranklist

                    # cat new[0-9][0-9].$TOPIC > x
                    if [ "$N" != "99" ] ; then
                        head -$L fused_ranklist | cut -d' ' -f1 > new$N.$TOPIC
                        # head -$L 1/new$N.$TOPIC > x; mv x new$N.$TOPIC
                    fi

                    echo "ASSESS!"
                    for SYS in {1..2}; do
                        pushd $SYS
                        cp ../new$N.$TOPIC ./
                        rm -rf rel.$TOPIC.Judged.doc.list
                        touch rel.$TOPIC.Judged.doc.list
                        while IFS='' read -r line || [[ -n $line ]]; do
                            RELFLAG=`cat ../../judgement/qrels.$JUDGECLASS.list | grep "$TOPIC 0 $line [1-9]" | cut -d' ' -f 4 | head -1`

                            if [ -z "$RELFLAG" ]; then
                                RELFLAG=0
                            fi

                            if [ $RELFLAG -ge $SYS ] ; then
                                echo $line 1 >> rel.$TOPIC.Judged.doc.list
                                echo $line 1 >> $TOPIC.record.list
                            else
                                echo $line 0 >> $TOPIC.record.list
                            fi
                        done < new$N.$TOPIC
                        cat rel.$TOPIC.Judged.doc.list >> rel.$TOPIC.fil
                        cat rel.$TOPIC.Judged.doc.list > rel.$TOPIC.$N.Judged.doc.list
                        RELFINDDOC=`wc -l < rel.$TOPIC.Judged.doc.list`
                        RELRATE=`echo "scale=4; $RELFINDDOC / $L" | bc`
                        CURRENTREL=`wc -l < rel.$TOPIC.fil`
                        echo $RELFINDDOC $L $RELRATE $CURRENTREL >> rel.rate

                        sort rel.$TOPIC.fil | sed -e 's/$/ 1/' > prel.$TOPIC

                        cut -d' ' -f1 prel.$TOPIC > rel.$TOPIC.fil

                        popd
                    done

                    NUM_REL=$(cat */rel.$TOPIC.fil | sort | uniq | wc -l)
                    TOT_REL=$(grep "^$TOPIC.*[1-9]$" ../judgement/qrels.$JUDGECLASS.list | cut -d' ' -f3 | sort | uniq | wc -l)
                    if [ $NUM_REL -eq $TOT_REL ]; then
                        break 2
                    fi


                    NDUN=$((NDUN+L))
                    L=$((L+(L+9)/10))
                fi
            done
        done
        # cp judge.effort.$TOPIC."$PURPOSE".dump ../result/dump/"$PURPOSE"/"$CORP"/judge.effort.$TOPIC."$PURPOSE".dump

        rm -rf svm.test.*
        popd

        mv $TOPIC result/"$PURPOSE"/"$CORP"/$TOPIC
        rm $TOPIC.seed.doc

    done < "judgement/$CORP.topic.stemming.txt"
    rm -rf "$CORP".svm.fil
    rm "$CORP".df

    rm N

    #Generate LSI from tfdf
    #python clustering/doLSI.py --input=tfdf_oldreut --output=LSIVector/"$CORP".lsi.dump --mapping=LSIVector/"$CORP".mapping.dump --latent=200 --choice=entropy --normalization=yes

done
