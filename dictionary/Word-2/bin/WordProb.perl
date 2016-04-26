#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                        WordProb.perl
#                             by Shinsuke Mori
#                             Last change : 8 June 2008
#=====================================================================================

# KKConv/Word-2/bin/WordYomiProb.perl �ذ�ư�Ѥ�

# ��  ǽ : ���ϵ��������Ф�����ǽ��ɽ���ȳ�Ψ�򻻽Ф���
#
# ����ˡ : WordProb.perl (STEM)
#
# ��  �� : WordProb.perl ~/SLM/text/MMH/MMH-L < yomi/02-gram
#
# ������ : ɸ�����Ϥ��ޤ�
#          ��Ψ�ι߽��˽��Ϥ���
#          ������ʬ�� sub search �����ˤ���


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use POSIX;
use English;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl",
        "$HOME/SLM/text/lib/perl");

require "Help.pm";
require "Char.pm";

require "SArray.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ����ؿ����������ɤ߹���
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # ��
use constant FAUX => 0;                           # ��

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 1) && ($ARGV[0] ne "-help")) || &Help($0);

$STEM = shift;

$PATH = dirname($STEM);
$STEM = basename($STEM);


#-------------------------------------------------------------------------------------
#                        ��ͭ���ѿ�������
#-------------------------------------------------------------------------------------

@WordMarkovTest = (&Morphs2Words($MorpMarkovTest))[0 .. 1];


#-------------------------------------------------------------------------------------
#                        $text ������
#-------------------------------------------------------------------------------------

$text = new SArray(join("/", $PATH, $STEM));

$text->test(qw( �� �ҥ����ߥ� ));                 # $text �Υƥ���


#-------------------------------------------------------------------------------------
#                        ñ��������
#-------------------------------------------------------------------------------------

# text �˽ФƤ��ʤ�ʸ��������

$TANKAN = "SLM/dict/tankan";
@FILE = qw( JIS1.text JIS2.text Kana.text Kigo.text Suji.text );
%TANKAN = ();                                     # �ɤ� => (ʸ��)+
#$CharYomi = 1;                                    # BT ��ʬ
foreach $FILE (@FILE){
    $FILE = join("/", $HOME, $TANKAN, $FILE);
    open(FILE) || die "Can't open $FILE: $!\n";
    while (chop($_ = <FILE>)){                    # main loop
        (m/^\#/) && next;                         # �������ȹ�
        (m/^\s*$/) && next;                       # ����
        ($char, @yomi) = split;
        ($text->Freq($char) > 0) || next;         # �������ѥ��˽и����ʤ�ʸ���ξ���
        foreach $yomi (@yomi){
            if (defined($TANKAN{$yomi})){
                push(@{$TANKAN{$yomi}}, $char);
            }else{
                $TANKAN{$yomi} = [$char];
            }
        }

#        $CharYomi += @yomi;
    }
    close(FILE);
}

#$yomi = "����";
#printf("%s => %s\n", $yomi, join(" ", @{$TANKAN{$yomi}}));
#exit(0);


#-------------------------------------------------------------------------------------
#                        ̤�θ��ɤߥ��ǥ�
#-------------------------------------------------------------------------------------

#$YOMIROOT = "$HOME/SLM/EDR/Yomi/Morp-2/Step0";
#
#$FILE = "$YOMIROOT/TankanIntStr.text";
#$TankanIntStr = new IntStr($FILE);
#$CharYomi -= ($TankanIntStr->size()-1);
#
#$LAMBDA = "$YOMIROOT/TankanLambda";
#open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
#@LforTankan = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
#close(LAMBDA);
#
#$FILE = "$YOMIROOT/TankanMarkov";
#$TankanMarkov = new MarkovHashMemo($TankanIntStr->size, $FILE);


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

while (chop($yomi = <>)){
    @line = ();
    &search($yomi, "", ());                       # �Ƶ�Ū��õ��(������DP�Ǥ����٤���)
#    print STDERR $yomi, "\n";
    foreach (@line){
        ($logP, $word, @elem) = split;
        printf("%10.5f %s %s\n", $logP, $word, join(" ", @elem));
    }
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#-------------------------------------------------------------------------------------
#                        calc
#-------------------------------------------------------------------------------------

# ��  ǽ : ɽ���ؤ�ʬ���κƵ�Ūõ��
#
# ������ : �������Х��ѿ� @line ���񤭴�����

sub search{
    (@_ > 1) || die;
    my($yomi) = shift;
    my($word) = shift;
    my(@pair) = @_;

    my($length) = length($yomi)/2;

    my($i);
    for ($i = 1; $i < $length; $i++){
        my($head) = substr($yomi, 0, 2*$i);
        foreach $char (@{$TANKAN{$head}}){
            my($temp) = $word . $char;
            ($text->Freq($temp) > 0) || next;     # �������ѥ��˽и����ʤ�ñ���ξ���
            &search(substr($yomi, 2*$i), $temp, (@pair, join("/", $char, $head)));
        }
    }
#    ($i == $length) || die;

    my($head) = substr($yomi, 0, 2*$i);
    foreach $char (@{$TANKAN{$head}}){
        my(@elem) = (@pair, join("/", $char, $head));
        my($temp) = $word . $char;
        ($text->Freq($temp) > 0) || next;         # �������ѥ��˽и����ʤ�ñ���ξ���
        print join(" ", @elem), "\n";             # ����
#        push(@line, sprintf("%10.5f %s %s", &ent(@elem), $temp, join(" ", @elem)));
    }
# $text->freq(...) > 0
# ���Ϥ� ( ɽ��/�ɤ�, logP ) �� for RCDict
    return;
}


#-------------------------------------------------------------------------------------
#                        ent
#-------------------------------------------------------------------------------------

# ��  ǽ : �����ȥ��ԡ��η׻�
#
# ������ : �ʤ�

sub ent{
    (@_ > 0) || die;
    my(@elem) = @_;

    my($logP) = 0;
    my($Tnum) = scalar(@elem)+1;

    my(@state) = ($TankanIntStr->int($BT)) x 1;
    foreach $char (@elem, $BT){                   # ʸ��ñ�̤Υ롼��
        push(@state, $TankanIntStr->int($char));
        if ($TankanMarkov->_1gram($state[0]) > 0){
            $p0 = 1/$TankanIntStr->size();
            $p1 = $TankanMarkov->_1prob($state[0]);
            $p2 = $TankanMarkov->_2prob(@state);
            $prob = $LforTankan[0]*$p0+$LforTankan[1]*$p1+$LforTankan[2]*$p2;
        }else{
            $p0 = 1/$TankanIntStr->size();
            $p1 = $TankanMarkov->_1prob($state[0]);
            $prob = $LforTankan[3]*$p0+$LforTankan[4]*$p1;
        }
        $logP += -log($prob);
        shift(@state);
    }

    return($logP);
}


#=====================================================================================
#                        END
#=====================================================================================
