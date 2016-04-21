#!/bin/csh -f
#=====================================================================================
#                       plot.csh
#                             bShinsuke Mori
#                             Last change 16 August 2011
#=====================================================================================

# 機  能 : 予測能力と解析精度のグラフを描く
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
#                        setvariables
#-------------------------------------------------------------------------------------

set PLOT = /usr/bin/gnuplot
set TEST = 10
#set TEST = MPT
set SUFF = accu
#set SUFF = peaccu
#set SUFF = wsaccu


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

echo "# TEST = " $TEST.$SUFF
set N = 1
#foreach FILE ( $TEST-????-??-??.$SUFF )
foreach FILE ( ????-??-??/$TEST.$SUFF )
#    echo -n $FILE
    printf "%02d" $N
    /usr/bin/tail -n -2 $FILE | head -1 | cut -f 3 -d=
    set N = `expr $N + 1`
end

#$PLOT $HOME/SLM/vir/lib/data.gnp

# set output "result.obj"
# set terminal tgif

# plot "/tmp/10.peaccu" with linespoints, "/tmp/MPT.peaccu" with linespoints, "/tmp/10.wsaccu" with linespoints, "/tmp/MPT.wsaccu" with linespoints

# plot [0:35] "/tmp/a" with linespoints, "/tmp/b" with linespoints


#=====================================================================================
#                        END
#=====================================================================================
