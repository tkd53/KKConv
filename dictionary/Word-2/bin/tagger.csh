#!/bin/csh -f
#=====================================================================================
#                       tagger.csh
#                             bShinsuke Mori
#                             Last change 4 October 2009
#=====================================================================================

# 機  能 : 分散形態素解析のためのラッパー
#
# 注意点 : ファイルのロックをしていない


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

set PROG = ../src/main


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

echo ===== $HOST =================================================================

#foreach FILE ( split/??? )
#foreach FILE ( ../bl-i-Step0/corpus/*.text )
#foreach FILE ( ../199[45]-01-09.text )
foreach FILE ( ../../75m-MNN/??? )
    if (! -e $FILE:r.tagger ) then
        echo ----- $FILE -------------------------------------------------------------
        $PROG < $FILE > $FILE:r.tagger
        echo
    endif
end


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================
