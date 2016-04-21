#!/usr/bin/env perl
#=====================================================================================
#                       WordMarkovDB.perl
#                             bShinsuke Mori
#                             Last change 12 May 2009
#=====================================================================================

# ��  ǽ : ñ��(ɽ��) 2-gram ���Ѥ��� Cross Entropy ���׻����롣
#
# ����ˡ : CrossEntropy.perl STEP N
#
# ��  �� : CrossEntropy.perl 0 3
#
# ������ : (filestem).morp �� "ɽ��/�ʻ� ..." �ȤʤäƤ��ʤ����Фʤ��ʤ���
#          �Կ��� 4**ARGV[0] �ǳ����ڤ���ʸ�������Ѥ��Ƴؽ����롣


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl");
($HOSTNAME =~ /arcs/) && unshift(@INC, "$HOME/usr/lib/perl/arcs");

require "Help.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 2) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�
$N = shift;                                       # �����ܤ���ʬ���ǥ뤫


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ����ؿ����������ɤ߹���
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # ��
use constant FAUX => 0;                           # ��

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        ��ͭ���ѿ�������
#-------------------------------------------------------------------------------------

$MO = 1;                                          # �ޥ륳�ե��ǥ��μ���

@WordMarkovTest = (&Line2Units($WordMarkovTest))[0 .. $MO];
(@WordMarkovTest > 0) || die;


#-------------------------------------------------------------------------------------
#                        $WordIntStr ������
#-------------------------------------------------------------------------------------

(-e ($FILE = "WordIntStr.text")) || die;
$WordIntStr = new IntStr($FILE);


#-------------------------------------------------------------------------------------
#                        ���������ѤΥޥ륳�ե��ǥ�������
#-------------------------------------------------------------------------------------

$WordMarkov = new MarkovHashMemo($WordIntStr->size);
&WordMarkov($WordMarkov, map(sprintf($CTEMPL, $_), grep($_ != $N, @Kcross)));
$WordMarkov->test($WordIntStr, @WordMarkovTest);

$FILE = sprintf("WordMarkov%02d", $N);
$WordMarkov->put($FILE);


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#=====================================================================================
#                        END
#=====================================================================================
