#!/bin/csh -f
#=====================================================================================
#                       kkc-loop.csh
#                             bShinsuke Mori
#                             Last change 15 July 2011
#=====================================================================================

# 機  能 : 実験
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

if ($#argv != 0) then
    echo "Usage: $0"
    exit(1)
endif


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

set DATE = `date +%Y-%m-%d`
#set DATE = test
set KYTEAOPT = "-encode euc -solver 7 -subword ../LR/tankan.wordkkci -dict ../LR/dict.wordkkci"


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

../bin/conv-log.perl slmkkc.log > $DATE.wordkkci

../bin/make-train.perl > $DATE-train.wordkkci

../kytea-0.3.2/src/bin/train-kytea $KYTEAOPT -full $DATE-train.wordkkci -model $DATE.kbm

echo Making Lall.wordkkci

/bin/cp $DATE-train.wordkkci Lall.wordkkci

../mksc/bin/mksc --notag 2 --ws 1 --tag 1 --model $DATE.kbm < ../LR/Lall.text >> Lall.wordkkci


#-------------------------------------------------------------------------------------
#                        コーパス作成
#-------------------------------------------------------------------------------------

/bin/mkdir -p ../corpus-$DATE
cd ../corpus-$DATE
split.perl %02d.wordkkci 9 ../kkclog/Lall.wordkkci

cd ../corpus
foreach FILE ( ../corpus-$DATE/0?.wordkkci )
    ln -f -s "$FILE"
end


#-------------------------------------------------------------------------------------
#                        モデル作成
#-------------------------------------------------------------------------------------

echo bin/MakeExpDir.csh $DATE
cd ../WordKKCI-2/
bin/MakeExpDir.csh $DATE

echo bin/MakeExpDir.csh $DATE
cd ../KKConv/WordKKCI-2/
bin/MakeExpDir.csh $DATE
/bin/rm latest
/bin/ln -s $DATE latest

echo bin/MakeExpDir.csh $DATE
cd ../Int-WordKKCI-2/
bin/MakeExpDir.csh $DATE
/bin/rm latest
/bin/ln -f -s $DATE latest


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================
