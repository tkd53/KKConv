#!/usr/bin/env perl
#=====================================================================================
#                       UkWord.perl
#                             bShinsuke Mori
#                             Last change 5 September 2010
#=====================================================================================

# 機  能 : 各コーパスに含まれる未知語を出力する。
#
# 使用法 : UkWord.perl (STEP) [FILENAME]
#
# 実  例 : UkWord.perl 4
#
# 注意点 : (filestem).morp は "表記/品詞 ..." となっていなければならない。
#          行数が 4**ARGV[0] で割り切れる文だけを対象とする。


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$TKD53HOME/lib/perl");

require "Help.pm";
require "class/IntStr.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

(((@ARGV == 1) || (@ARGV == 2)) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";

$STEP = 4**shift;                                 # 学習コーパスの文のステップ
$TEST = (@ARGV) ? shift : undef;


#-------------------------------------------------------------------------------------
#                        共通の変数や関数の定義を読み込む
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWordKKCI.perl";


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

$WordIntStr = new IntStr("WordIntStr.text");

if ($TEST){
    @FILE = ($TEST);
}else{
    @FILE = map(sprintf($CTEMPL, $_), @Kcross);
}

foreach $FILE (@FILE){
    open(FILE) || die "Can't open $FILE: $!\n";
    warn $FILE, "\n";
    while (<FILE>){
        next if (($.%$STEP != 0) && ($n != 10));
        foreach (&Line2Units($_)){
            next if ($WordIntStr->int($_));
            print $_, "\n";
        }
    }
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        exit
#-------------------------------------------------------------------------------------

exit(0);


#=====================================================================================
#                        END
#=====================================================================================
