#!/bin/csh -f
#=====================================================================================
#                       ME-apply.csh
#                             bShinsuke Mori
#                             Last change 8 October 2009
#=====================================================================================

# ��  ǽ : ME �ˤ��ñ��ʬ�� (ñ�춭����Ψ����)
#
# ����ˡ : ME-apply.csh (FILENAME|DIRECTORY)
#
# ��  �� : ME-apply.csh 1994.text
#
# ����� : ME-model/ �Ǽ¹Ԥ��٤�


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

if ($#argv != 1) then
    echo "Usage: $0 (FILENAME)"
    exit(1)
endif

set TC = $1;


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

set TOOL = $HOME/link/resource/tool

set PROG = $TOOL/MaxEntBTProb/perl/jws.perl
set AMIS = $TOOL/MaxEntBTProb/amis-4.0/src/amis


#-------------------------------------------------------------------------------------

#set LC = ../corpus/01-10.word
#set LC = ../corpus/01-09.word
#set WORD = ../dict/dict.word
#set WORD = ../dict/75m-dict.word
#set WORD = ../dict/mori.word
#set COMP = ../dict/dict.comp

#set STEM = $LC:t:r+$WORD:t:r+$COMP:t:r
#set STEM = $LC:t:r+$WORD:t:r
#set STEM = $LC:t:r
#set STEM = 01-10+unidic

# for SLM/ALL
#set LC = ../corpus/01-09.word
#set WORD = ~/link/resource/dict/word/2009-06-26-unidic/unidic.word
#set STEM = 01-09+unidic

#For LREC2010
set LC = ../corpus/01-09.word
set WORD = ../dict/unidic.word
set STEM = $LC:t:r+$WORD:t:r

echo HOST = $HOST
echo "( LC, WORD, STEM ) = (" $LC, $WORD, $STEM ")"
#exit


#-------------------------------------------------------------------------------------

#set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS --Vocab=$WORD --Phrase=$COMP"
set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS --Vocab=$WORD"
#set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS"

echo "OPTION = " $OPTION


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

#if (-f $TC) then                                  # �ե�����ξ��
  echo Segmenting $TC ...
  set OPSTEM = $TC:r

  $PROG $OPTION --test=$TC --model=$STEM --output=$OPSTEM.mewseg --prob=$OPSTEM.btprob
#else                                              # �ǥ��쥯�ȥ�ξ��
#  foreach FILE ( $TC/*.text )
#    if (! -e $FILE:r.mewseg ) then
#        echo ----- $FILE -------------------------------------------------------------
#        set OPSTEM = $FILE:r
#        $PROG $OPTION --test=$FILE --model=$STEM --output=$OPSTEM.mewseg \
#          --prob=$OPSTEM.btprob
#        echo
#    endif
#endif


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================
