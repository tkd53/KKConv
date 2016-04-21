#!/bin/csh -f
#=====================================================================================
#                       temp-ME-apply.csh
#                             bShinsuke Mori
#                             Last change 18 August 2009
#=====================================================================================

# 機  能 : ME による単語分割 (単語境界確率推定)
#
# 使用法 : ME-apply.csh (FILENAME|DIRECTORY)
#
# 実  例 : ME-apply.csh 1994.text
#
# 注意点 : ME-model/ で実行すべし


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
set LC = ../corpus/01-09.word
#set WORD = ../dict/word
set WORD = ../dict/unidic.word
#set COMP = ../dict/comp

#set STEM = $LC:t:r+$WORD:t:r+$COMP:t:r
#set STEM = $LC:t:r+$WORD:t:r
#set STEM = $LC:t:r
set STEM = 01-09+unidic

#echo $STEM
#exit


#-------------------------------------------------------------------------------------

#set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS --Vocab=$WORD --Phrase=$COMP"
set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS --Vocab=$WORD"
#set OPTION = "--MEcommand=$AMIS -u 0 -a BFGS"

echo "OPTION = " $OPTION


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

#if (-f $TC) then                                  # ファイルの場合
  echo Segmenting $TC ...
  set OPSTEM = $TC:r

  $PROG $OPTION --test=$TC --model=$STEM --output=$OPSTEM.mewseg --prob=$OPSTEM.btprob
#else                                              # ディレクトリの場合
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
