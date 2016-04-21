#!/usr/bin/perl
#=====================================================================================
#                       tagger2word.perl
#                             bShinsuke Mori
#                             Last change 31 October 2009
#=====================================================================================

# ��  ǽ : �����ǲ��Ϥη�̤� .depend �η������Ѵ����롣
#
# ����ˡ : tagger2depend.perl [filename ...]
#
# ��  �� : tagger2depend.perl EHJ.tagger
#
# ������ : �ʤ�


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl"); # ������ץȤΥѥ��� @INC �˲ä���

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