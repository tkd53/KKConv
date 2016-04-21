#!/bin/csh -f
#=====================================================================================
#                       ME-learn.csh
#                             bShinsuke Mori
#                             Last change 31 October 2009
#=====================================================================================

# ��  ǽ : ME �γؽ�
#
# ����ˡ : ME-learn.csh
#
# ��  �� : ME-learn.csh
#
# ����� : ME-model/ �Ǽ¹Ԥ��٤�


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

if ($#argv != 0) then
    echo "Usage: $"
    exit(1)
endif


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

set TOOL = $HOME/link/resource/tool

set PROG = $TOOL/MaxEntBTProb/perl/jws.perl
set AMIS = $TOOL/MaxEntBTProb/amis-4.0/src/amis


#-------------------------------------------------------------------------------------

#set LC = ../corpus/01-10.word
#set WORD = ../dict/dict.word
#set WORD = ../dict/75m-dict.word
#set WORD = ../dict/mori.word
#set COMP = ../dict/dict.comp

#set STEM = $LC:t:r+$WORD:t:r+$COMP:t:r
#set STEM = $LC:t:r+$WORD:t:r
#set STEM = $LC:t:r
#set STEM = 01-09+unidic
#set STEM = 01-10+unidic

#V.S. kyws
set LC = $HOME/link/resource/tool/kyws/corpus/01-09.word
set WORD = $HOME/link/resource/tool/kyws/dict/unidic++.word
set STEM = vs-kyws

echo HOST = $HOST
echo "( LC, WORD, STEM ) = (" $LC, $WORD, $STEM ")"
#echo "( LC, WORD, STEM ) = (" $LC, NULL, $STEM ")"
#exit


#-------------------------------------------------------------------------------------

set TC = ../corpus/10.sent                        # �ƥ��ȥ����ѥ�


#-------------------------------------------------------------------------------------

set ACCUPROG = $HOME/SLM/vir/Word-2/bin/Accuracy.perl
set BDACCUPROG = $HOME/SLM/vir/Word-2/bin/BoundaryAccuracy.perl


#-------------------------------------------------------------------------------------

#set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS --Vocab=$WORD --Phrase=$COMP"
#set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS --Vocab=$WORD"
set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS"

echo "OPTION = " $OPTION


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

echo Learning ...

$PROG $OPTION --train=$LC --model=$STEM


#-------------------------------------------------------------------------------------

echo Testing ...

set OPSTEM = $TC:t:r

$PROG $OPTION --test=$TC --model=$STEM --output=$OPSTEM.mewseg --prob=$OPSTEM.btprob


#-------------------------------------------------------------------------------------

$ACCUPROG $OPSTEM.mewseg $TC:r.word > $OPSTEM.accu
$BDACCUPROG $OPSTEM.mewseg $TC:r.word >> $OPSTEM.accu

/usr/bin/tail -4 $OPSTEM.accu


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================
