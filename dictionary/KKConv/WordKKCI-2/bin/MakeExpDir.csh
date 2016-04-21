#!/bin/csh -f
#=====================================================================================
#                       MakeExpDir.csh
#                             bShinsuke Mori
#                             Last change 9 July 2011
#=====================================================================================

# ��  ǽ : DATE ���������
#
# ����ˡ : MakeDir.csh (DATE)
#
# ��  �� : MakeDir.csh 2011-07-08
#
# ����� : ������񸻤���γؽ��¸�
#          STEP = 0


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

if ($#argv != 1) then
    echo "Usage: $0 (DATE)"
    exit(1)
endif


#-------------------------------------------------------------------------------------
#                        setvariables
#-------------------------------------------------------------------------------------

set DATE = $argv[1]
set STEP = 0
set CORPUS = ../../../../corpus
set TEST = 10

set UMCONV = ../../WordKKCI-2/bin/KatakanaUM.perl # ?
set ACCU   = ../../Word-2/bin/Accuracy.perl


#-------------------------------------------------------------------------------------
#                        Dir �κ���
#-------------------------------------------------------------------------------------

/bin/mkdir -p $DATE
cd $DATE


#-------------------------------------------------------------------------------------
#                        WordKKCI-2 �ؤΥ�󥯤κ���
#-------------------------------------------------------------------------------------

foreach FILE ( WordIntStr.text WordLambda WordMarkov.db \
               CharIntStr.text CharLambda CharMarkov.db )
    ln -f -s "../../../WordKKCI-2/$DATE/$FILE"
end


#-------------------------------------------------------------------------------------
#                        ̤�θ��ǥ�κ���
#-------------------------------------------------------------------------------------

../bin/MakeUnknownWordModel.perl $STEP >& MakeUnknownWordModel.log


#-------------------------------------------------------------------------------------
#                        ��������κ���
#-------------------------------------------------------------------------------------

if (! (-r InDict.datran && -r InDict.dadata)) then
    ../bin/MakeInDictDA.perl $STEP >& MakeInDictDA.log
endif

#if (! (-r InDict.actran && -r InDict.acdata)) then
#    ../bin/MakeInDictAC.perl $STEP >& MakeInDictAC.log
#endif
#exit

#-------------------------------------------------------------------------------------
#                        ��������κ���
#-------------------------------------------------------------------------------------

if (! (-r ExDict.wordkkci)) then
   ( ../bin/UkWord.perl $STEP | sort -u > ExDict.wordkkci ) >& UkWord.log
endif

if (! (-r ExDict.datran && -r ExDict.dadata)) then
   ../bin/MakeExDictDA.perl ExDict.wordkkci >& MakeExDictDA.log
endif

if (! (-r ExDict.actran && -r ExDict.acdata)) then
   ../bin/MakeExDictAC.perl ExDict.text >& MakeExDictAC.log
endif


#-------------------------------------------------------------------------------------
#                        ��̾�����Ѵ�
#-------------------------------------------------------------------------------------

if ($#argv == 2) then
    if ($argv[2] > 0) then
        ( head -$argv[2] $CORPUS/$TEST.kkci | ../arcs-src/main | $UMCONV \
          > $TEST-$argv[2].kkconv ) >& kkconv.log
        $ACCU $TEST-$argv[2].kkconv $CORPUS/$TEST.sent > $TEST-$argv[2].accu
    endif

else
    ( ../arcs-src/main < $CORPUS/$TEST.kkci | $UMCONV > $TEST.kkconv ) >& kkconv.log
    $ACCU $TEST.kkconv $CORPUS/$TEST.sent > $TEST.accu
endif


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================
