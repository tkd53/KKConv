#!/bin/csh -f
#=====================================================================================
#                        MakeDir.csh
#                             by Shinsuke MORI
#                             Last change : 19 November 2001
#=====================================================================================

# 実験用スクリプト


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

if ($#argv != 1) then
    echo "Usage: $0 (STEP)"
    exit(1)
endif


#-------------------------------------------------------------------------------------
#                        setvariables
#-------------------------------------------------------------------------------------

set STEP = $argv[1]


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

cd Morp-2
if (! -e Step$STEP) then
    echo \[$PWD\]% bin/MakeDir.csh $STEP 0
    bin/MakeDir.csh $STEP 0
endif
cd ..

cd Clst-2
if (! -e Step$STEP) then
    echo \[$PWD\]% bin/MakeDir.csh $STEP 0
    bin/MakeDir.csh $STEP 0
endif
cd ..

cd Int-Clst-2
if (! -e Step$STEP) then
    echo \[$PWD\]% bin/MakeDir.csh $STEP
    bin/MakeDir.csh $STEP
endif
cat Step$STEP/*.accu


#=====================================================================================
#                        END
#=====================================================================================
