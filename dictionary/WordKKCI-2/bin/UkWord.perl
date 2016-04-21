#!/usr/bin/env perl
#=====================================================================================
#                       UkWord.perl
#                             bShinsuke Mori
#                             Last change 5 September 2010
#=====================================================================================

# ��  ǽ : �ƥ����ѥ��˴ޤޤ��̤�θ����Ϥ��롣
#
# ����ˡ : UkWord.perl (STEP) [FILENAME]
#
# ��  �� : UkWord.perl 4
#
# ������ : (filestem).morp �� "ɽ��/�ʻ� ..." �ȤʤäƤ��ʤ���Фʤ�ʤ���
#          �Կ��� 4**ARGV[0] �ǳ���ڤ��ʸ�������оݤȤ��롣


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$TK53HOME/lib/perl");

require "Help.pm";
require "class/IntStr.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

(((@ARGV == 1) || (@ARGV == 2)) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�
$TEST = (@ARGV) ? shift : undef;


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ���ؿ���������ɤ߹���
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