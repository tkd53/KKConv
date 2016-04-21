#!/bin/csh -f
#=====================================================================================
#                       eval.csh
#                             bShinsuke Mori
#                             Last change 25 December 2011
#=====================================================================================

# 機  能 : 各ループでのモデルの評価
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

#set KYTEAOPT = "-encode euc "

set WSACCU = $HOME/SLM/vir/Word-2/bin/Accuracy.perl
set PEACCU = $HOME/SLM/vir/Yomi/Word-2/bin/Accuracy.perl


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

/bin/mkdir -p eval

foreach DATE ( ????-??-??.kbm )
#foreach DATE ( 2011-08-0[6-9].kbm 2011-08-1?.kbm )

    set DATE = $DATE:r
    echo $DATE

    ../kytea-0.3.2/src/bin/kytea -model $DATE.kbm < ../corpus/10.sent > eval/10-$DATE.tagger

    $WSACCU eval/10-$DATE.tagger ../corpus/10.word > eval/10-$DATE.wsaccu

    $PEACCU eval/10-$DATE.tagger ../corpus/10.wordkkci > eval/10-$DATE.peaccu

    ../kytea-0.3.2/src/bin/kytea -model $DATE.kbm < ../corpus/MPT.sent > eval/MPT-$DATE.tagger

    $WSACCU eval/MPT-$DATE.tagger ../corpus/MPT.word > eval/MPT-$DATE.wsaccu

    $PEACCU eval/MPT-$DATE.tagger ../corpus/MPT.wordkkci > eval/MPT-$DATE.peaccu

end


#-------------------------------------------------------------------------------------
#                        table
#-------------------------------------------------------------------------------------

/usr/bin/tail -n -2 eval/10-*.wsaccu > 10.wsaccu
/usr/bin/tail -n -2 eval/10-*.peaccu > 10.peaccu

/usr/bin/tail -n -2 eval/MPT-*.wsaccu > MPT.wsaccu
/usr/bin/tail -n -2 eval/MPT-*.peaccu > MPT.peaccu


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================
