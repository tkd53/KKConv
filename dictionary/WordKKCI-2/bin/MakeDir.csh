#!/bin/csh -f
#=====================================================================================
#                       MakeDir.csh
#                             bShinsuke Mori
#                             Last change 16 September 2012
#=====================================================================================

# 機  能 : STEP(STEP) を作成する
#
# 使用法 : MakeDir.csh (STEP)
#
# 実  例 : MakeDir.csh 0
#
# 注意点 : 単語分割(読み推定)がまだ


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

set ACCU   = ../Word-2/bin/Accuracy.perl

#-------------------------------------------------------------------------------------
#                        Dir の作成
#-------------------------------------------------------------------------------------

/bin/mkdir -p Step$STEP
cd Step$STEP


#-------------------------------------------------------------------------------------
#                        LM の作成
#-------------------------------------------------------------------------------------

if (! (-r WordMarkov.db && -r WordLambda && -r Char)) then
    ../bin/CrossEntropy.perl $STEP >& log
endif

#-------------------------------------------------------------------------------------
#                        コーパスの統計
#-------------------------------------------------------------------------------------

( ../bin/CorpusStat.perl $STEP > CorpusStat ) >& /dev/null


#-------------------------------------------------------------------------------------
#                        内部辞書の作成
#-------------------------------------------------------------------------------------

echo Skipping Word Seg.
echo Done $0
exit


if (! (-r InDict.datran && -r InDict.dadata)) then
    ../bin/MakeInDictDA.perl >& MakeInDictDA.log
endif

#if (! (-r InDict.actran && -r InDict.acdata)) then
#    ../bin/MakeInDictAC.perl >& MakeInDictAC.log
#endif


#-------------------------------------------------------------------------------------
#                        外部辞書の作成
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
#                        単語分割
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
