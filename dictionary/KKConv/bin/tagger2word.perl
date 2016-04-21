#!/usr/bin/perl
#=====================================================================================
#                       tagger2word.perl
#                             bShinsuke Mori
#                             Last change 31 October 2009
#=====================================================================================

# 機  能 : 形態素解析の結果を .depend の形式に変換する。
#
# 使用法 : tagger2depend.perl [filename ...]
#
# 実  例 : tagger2depend.perl EHJ.tagger
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl"); # スクリプトのパスを @INC に加える

require "Help.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

($ARGV[0] eq "-help") && &Help($0);


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

while (<>){
#    s/(\d{6}IN|IN|EX|UM)//g;
    @elem = split;
#    pop(@elem);                                   # logP
    @word = map((split("/"))[0], @elem);
    print join(" ", @word), "\n";
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#=====================================================================================
#                        END
#=====================================================================================
