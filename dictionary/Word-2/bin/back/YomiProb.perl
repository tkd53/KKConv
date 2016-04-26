#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                        YomiProb.perl
#                             by Shinsuke Mori
#                             Last change : 7 June 2008
#=====================================================================================

# ��  ǽ : ñ��(ʸ����)�β�ǽ���ɤߤȤ��γ�Ψ�򻻽Ф���
#
# ����ˡ : YomiProb.perl (Filename)
#
# ��  �� : YomiProb.perl WordIntStr.text
#
# ������ : ���Ϥ�������Ψ�ͤ� -log ��P(<x,y>) �Ǥ��롣
#          ��Ψ�ι߽��˽��Ϥ���


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
require "Math.pm";
require "Char.pm";
require "MinMax.pm";

require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

($ARGV[0] ne "-help") || &Help($0);


#-------------------------------------------------------------------------------------
#                        ñ��������
#-------------------------------------------------------------------------------------

$TANKAN = "SLM/dict/tankan";
@FILE = qw( JIS1.text JIS2.text Kana.text Kigo.text Suji.text );
%TANKAN = ();
$CharYomi = 1;                                    # BT ��ʬ
print STDERR "Reading ";
foreach $FILE (@FILE){
    print STDERR $FILE, " ... ";
    $FILE = join("/", $HOME, $TANKAN, $FILE);
    open(FILE) || die "Can't open $FILE: $!\n";
    while (chop($_ = <FILE>)){                    # main loop
        (m/^\#/) && next;                         # �������ȹ�
        (m/^\s*$/) && next;                       # ����
        ($char, @yomi) = split;
        $TANKAN{$char} = [@yomi];
        $CharYomi += @yomi;
    }
    close(FILE);
}
print STDERR "done\n";


#-------------------------------------------------------------------------------------
#                        ̤�θ��ɤߥ��ǥ�
#-------------------------------------------------------------------------------------

$YOMIROOT = "$HOME/SLM/EDR/Yomi/Morp-2/Step0";

$FILE = "$YOMIROOT/TankanIntStr.text";
$TankanIntStr = new IntStr($FILE);
$CharYomi -= ($TankanIntStr->size()-1);

$LAMBDA = "$YOMIROOT/TankanLambda";
open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
@LforTankan = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
close(LAMBDA);

$FILE = "$YOMIROOT/TankanMarkov";
$TankanMarkov = new MarkovHashMemo($TankanIntStr->size, $FILE);


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

while (chop($word = <>)){
    print $word, "\n", join("\n", sort(&calc($word))), "\n\n";
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#-------------------------------------------------------------------------------------
#                        calc
#-------------------------------------------------------------------------------------

sub calc{
    (@_ == 1) || die;
    my($word) = shift;
    my(@char) = ($word =~ m/(..)/g);

    my(@line) = ();
    my(@suff) = (0) x @char;                      # �ɤߤ�ź��
    my(@SUFF) = map(scalar(@{$TANKAN{$_}}), @char);   # ź���ξ���

    do {                                          # ���Ƥ� [ɽ��, �ɤ�] ���ȹ礻
        my(@elem) = ();
        for ($i = 0; $i < @suff; $i++){           # ��ʸ�����֤��Ф����롼��
            push(@elem, join("/", $char[$i], ${$TANKAN{$char[$i]}}[$suff[$i]]));
        }

        push(@line, sprintf("%10.5f %s %s", &ent(@elem), $word, join(" ", @elem)));
    } while (&inc(\@suff, \@SUFF));

    return(@line);
}


#-------------------------------------------------------------------------------------
#                        inc
#-------------------------------------------------------------------------------------

# ��  ǽ : ź���Υ��󥯥�������
#
# ������ : �ʤ�

sub inc{
    (@_ == 2) || die;
    my($suff, $SUFF) = @_;

    for ($i = 0; $i < @$suff; $i++){
        $$suff[$i]++;
        if ($$suff[$i] == $$SUFF[$i]){            # ���夬��
            $$suff[$i] = 0;
        }else{
            return(1);
        }
    }

    return(0);                                    # ���Ƥ��ȹ礻���Ԥ�����
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
