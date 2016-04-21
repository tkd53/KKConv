#!/bin/csh -f
#=====================================================================================
#                       PSSCLambdaCorpus.csh
#                             bShinsuke Mori
#                             Last change 22 December 2008
#=====================================================================================

# 機  能 : 疑似確率分割のための実験用スクリプト
#
# 使用法 : PSSCLambdaCorpus.csh (PATH) (MULT)
#
# 実  例 : PSSCLambdaCorpus.csh ../SSC-Step0/corpus 64
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

if ($#argv != 2) then
    echo "Usage: $0 (PATH) (MULT)"
    exit(1)
endif


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

set PATH = $argv[1]
set MULT = $argv[2]

set PORG = $HOME/link/resource/tool/StochSegCorpus/bin/MonteCarlo-SSC.perl


#-------------------------------------------------------------------------------------
#                        ディレクトリの作成
#-------------------------------------------------------------------------------------

/bin/mkdir -p corpus


#-------------------------------------------------------------------------------------
#                        部分学習コーパスの作成
#-------------------------------------------------------------------------------------

# 擬似確率分割

foreach N ( `seq -f %02g 1 9` )
    echo $N
    touch corpus/$N.word
    foreach DIR ( `seq -w 1 $MULT` )
        $PORG $PATH/$N >> corpus/$N.word
    end
end


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

echo Done $0
exit


#=====================================================================================
#                        END
#=====================================================================================
