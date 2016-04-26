#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       SortWordByFreq.perl
#                             bShinsuke Mori
#                             Last change 16 September 2012
#=====================================================================================

# 機  能 : 形態素を頻度の降順に頻度と共に出力
#
# 使用法 : SortMorpByFreq.perl (STEP)
#
# 実  例 : SortMorpByFreq.perl 0
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use English;
use File::Basename;
unshift(@INC, "$TKD53HOME/lib/perl");

require "Help.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 1) && ($ARGV[0] ne "-help")) || &Help($0);

$STEP = 4**shift;                                 # 学習コーパスの文のステップ


#-------------------------------------------------------------------------------------
#                        共通の変数や関数の定義を読み込む
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # 真
use constant FAUX => 0;                           # 偽

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWordKKCI.perl";


#-------------------------------------------------------------------------------------
#                        固有の変数の定義
#-------------------------------------------------------------------------------------

$MO = 1;                                          # マルコフモデルの次数

@WordMarkovTest = (&Line2Units($WordMarkovTest))[0 .. $MO];


#-------------------------------------------------------------------------------------
#                        $WordIntStr の生成
#-------------------------------------------------------------------------------------

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        $WordMarkov の生成
#-------------------------------------------------------------------------------------

if (-e (($FILE = "WordMarkov") . $MarkovHash::SUFFIX)){
#    $WordMarkov = new MarkovHashMemo($WordIntStr->size, $FILE);
    $WordMarkov = new MarkovHashDisk($WordIntStr->size, $FILE);
}else{
    $WordMarkov = new MarkovHashMemo($WordIntStr->size);
    &WordMarkov($WordMarkov, map(sprintf($CTEMPL, $_), @Kcross));
    $DIRE = "/dev/shm";                           # 時間がかかるので一旦 RAM DISK に
    $WordMarkov->put("$DIRE/$FILE");
    system("/bin/mv $DIRE/$FILE.db .");
}
#$WordMarkov->test($WordIntStr, @WordMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        整列
#-------------------------------------------------------------------------------------

printf(STDERR "Sorting ... ");

@suff = sort { $WordMarkov->_1gram($b) <=> $WordMarkov->_1gram($a) }
             (scalar(@Tokens) .. $WordIntStr->size()-1);

printf(STDERR "Done\n");


#-------------------------------------------------------------------------------------
#                        出力
#-------------------------------------------------------------------------------------

printf(STDERR "Writing ... ");

foreach $n (@suff){
    printf("%6d %s\n", $WordMarkov->_1gram($n), $WordIntStr->str($n));
}

printf(STDERR "Done\n", $FILE);


#-------------------------------------------------------------------------------------
#                        exit
#-------------------------------------------------------------------------------------

exit(0);


#=====================================================================================
#                        END
#=====================================================================================
