#!/bin/csh -f
#=====================================================================================
#                       MakeDir.csh
#                             bShinsuke Mori
#                             Last change 14 April 2015
#=====================================================================================

# ��  ǽ : STEP(STEP) ���������
#
# ����ˡ : MakeDir.csh (STEP)
#
# ��  �� : MakeDir.csh 0
#
# ������ : AC Dict �б����ޤ�


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

if ($#argv != 1 && $#argv != 2) then
    echo "Usage: $0 (STEP) [LINE]"
    exit(1)
endif


#-------------------------------------------------------------------------------------
#                        setvariables
#-------------------------------------------------------------------------------------

set STEP = $argv[1]
set CORPUS = ../../corpus
set TEST = 10

set ACCU   = ../../Word-2/bin/Accuracy.perl


#-------------------------------------------------------------------------------------
#                        Dir �κ���
#-------------------------------------------------------------------------------------

/bin/mkdir -p Step$STEP
cd Step$STEP


#-------------------------------------------------------------------------------------
#                        LM �κ���
#-------------------------------------------------------------------------------------

#if (! (-r WordMarkov.db && -r WordLambda && -r Char)) then
    ../bin/CrossEntropy.perl $STEP >& log
#endif


#-------------------------------------------------------------------------------------
#                        �����ѥ�������
#-------------------------------------------------------------------------------------

( ../bin/CorpusStat.perl $STEP > CorpusStat ) >& /dev/null


#-------------------------------------------------------------------------------------
#                        ��������κ���
#-------------------------------------------------------------------------------------

if (! (-r InDict.datran && -r InDict.dadata)) then
    ../bin/MakeInDictDA.perl >& MakeInDictDA.log
endif

#if (! (-r InDict.actran && -r InDict.acdata)) then
#    ../bin/MakeInDictAC.perl >& MakeInDictAC.log
#endif


#-------------------------------------------------------------------------------------
#                        ��������κ���
#-------------------------------------------------------------------------------------

if (! (-r ExDict.text)) then
    ( ../bin/UkWord.perl $STEP | sort -u > ExDict.text ) >& /dev/null
endif

if (! (-r ExDict.datran && -r ExDict.dadata)) then
    ../bin/MakeExDictDA.perl ExDict.text >& MakeExDictDA.log
endif

#if (! (-r ExDict.actran && -r ExDict.acdata)) then
#    ../bin/MakeExDictAC.perl ExDict.text >& MakeExDictAC.log
#endif


#-------------------------------------------------------------------------------------
#                        ñ��ʬ��
#-------------------------------------------------------------------------------------

if ($#argv == 2) then
    if ($argv[2] > 0) then
        ( head -$argv[2] $CORPUS/$TEST.sent | ../src/main > $TEST-$argv[2].tagger ) \
        >& tagger.log
        $ACCU $TEST-$argv[2].tagger $CORPUS/$TEST.word > $TEST-$argv[2].accu
    endif
else
    ( ../src/main < $CORPUS/$TEST.sent > $TEST.tagger ) >& tagger.log
    $ACCU $TEST.tagger $CORPUS/$TEST.word > $TEST.accu
endif


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================