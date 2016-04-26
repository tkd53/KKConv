#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                        CrossEntropyWithBase.perl
#                             by Shinsuke Mori
#                             Last change : 9 May 2008
#=====================================================================================

# ��  ǽ : �١�����ñ��(ɽ��) 2-gram ���Ѥ��� Cross Entropy ���׻����롣
#
# ����ˡ : CrossEntropyWithBase.perl STEP BASE
#
# ��  �� : CrossEntropyWithBase.perl 4 $HOME/SLM/SKN/Word-2/Step0/
#
# ������ : ���줾����ñ�� 2-gram ���ǥ�����Ω�ˤ���ɬ�פ�����
#          �١������ǥ����ѿ��ˤ� Base ����Ƭ�����Ѥ��Ƥ���


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl");

require "Help.pm";
require "Math.pm";
require "MinMax.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

(((@ARGV == 2) || (@ARGV == 3)) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�
$BASE = shift;                                    # �١����θ������ǥ��Υѥ�
$TEST = (@ARGV) ? shift : undef;


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ����ؿ����������ɤ߹���
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        ��ͭ���ѿ�������
#-------------------------------------------------------------------------------------

$MO = 1;                                          # �ޥ륳�ե��ǥ��μ���

@WordMarkovTest = (&Morphs2Words($MorpMarkovTest))[0 .. $MO];


#-------------------------------------------------------------------------------------
#                        �������Υ��ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($WordIntStr, $WordMarkov, @LforWord) = &Read2gramModel("Word");

$WordMarkov->test($WordIntStr, @WordMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        �١�����ñ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($BaseWordIntStr, $BaseWordMarkov, @BaseLforWord) = &Read2gramModel("$BASE/Word");

$BaseWordMarkov->test($BaseWordIntStr, @WordMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        ʸ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);

#$CharMarkov->test($CharIntStr, @CharMarkovTest);


#-------------------------------------------------------------------------------------
#                        ���ַ����ο���
#-------------------------------------------------------------------------------------

$LAMBDA = "WithBaseLambda";
(-r $LAMBDA) || &CalcLambda($MO, $LAMBDA);        # �ե����뤬�ʤ����з׻�

@LforBase = &ReadLambda($LAMBDA);


#-------------------------------------------------------------------------------------
#                        �����ȥ��ԡ��η׻�
#-------------------------------------------------------------------------------------

$FLAG = VRAI;                                     # ʸ���Υ�����ɽ��
$FLAG = FAUX;

$CORPUS = $TEST ? $TEST : sprintf($CTEMPL, 10);   # �ƥ��ȥ����ѥ�
open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";
for ($logP = 0, $Cnum = 0, $Wnum = 0; <CORPUS>; ){
    $Cnum += scalar(&Morphs2Chars($_))+1;
    $Wnum += scalar(&Morphs2Words($_))+1;

    my(@word) = ($BT) x $MO;
    foreach $word (&Morphs2Words($_), $BT){       # ñ��ñ�̤Υ롼��
        push(@word, $word);

        @stat = map($WordIntStr->int($_), @word);
        $Pt = $WordMarkov->prob(@stat, @LforWord);
        if ($stat[$MO] == $WordIntStr->int($UT)){ # ̤�θ��ξ���
            $Pt *= exp(-&UWlogP($word));
        }

        @stat = map($BaseWordIntStr->int($_), @word);
        $Pb = $BaseWordMarkov->prob(@stat, @BaseLforWord);
        if ($stat[$MO] == $BaseWordIntStr->int($UT)){ # ̤�θ��ξ���
            $Pb *= exp(-&UWlogP($word));
        }

        $logP += -log($LforBase[0]*$Pt+$LforBase[1]*$Pb);

        shift(@word);
    }
    chop($line);
}
close(CORPUS);

printf(STDERR "ʸ���� = %d, H = %8.6f\n", $Cnum, $logP/$Cnum/log(2));
printf(STDERR "ñ���� = %d, PP = %8.6f\n", $Wnum, exp($logP/$Wnum));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#-------------------------------------------------------------------------------------
#                        CalcLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ���ַ����ο���

sub CalcLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե��ǥ��μ���
    my($LAMBDA) = shift;                          # ���ַ����Υե�����̾

    my(@WordMarkov);                              # �������Х��ǡ��������ѤΥ��ǥ�
    foreach $n (@Kcross){                         # ���������ѤΥޥ륳�ե��ǥ�������
        $WordMarkov[$n] = new MarkovHashMemo($WordIntStr->size);
#        $FILE = sprintf("WordMarkov%02d", $n);
#        $WordMarkov[$n] = new MarkovHashDisk($WordIntStr->size, $FILE);
        &WordMarkov($WordMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $WordMarkov[$n]->test($WordIntStr, @WordMarkovTest);
#        $WordMarkov[$n]->put($FILE);
        warn "\n";
    }

    my(@Tran) = map({}, @Kcross);                 # [(������, ����)+]+
    foreach $n (@Kcross){                         # �����ѥ������������ɤ߹���
        $FILE = sprintf($CTEMPL, $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){
            ($.%$STEP == 0) || next;
            @word = (($BT) x $MO, &Morphs2Words($_), $BT);
            grep(! ${$Tran[$n]}{join(" ", @word[$_-$MO .. $_])}++, ($MO .. $#word));
        }
        close(FILE);
#        while (($key, $val) = each(%{$Tran[$n]})){
#            printf("f(%s) = %d\n", $key, $val);
#        }
    }

    my($TEMPLATE) = "%6.4f";                      # ���ַ��������ӷ���
    my(@Lnew) = (1/2, 1/2);                       # EM���르�ꥺ���ν�����
    do {                                          # EM���르�ꥺ���Υ롼��
        @LforBase = @Lnew;                        # �����ȥ��å���
        @Lnew = (0) x @LforBase;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = &OneIteration($WordMarkov[$n], $Tran[$n], @LforBase);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#Lnew));
        }
        @Lnew = map($_/scalar(@Kcross), @Lnew);
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforBase));

    my($FILE) = "> $LAMBDA";                      # ���ַ����ե�����������
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforBase)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        OneIteration
#-------------------------------------------------------------------------------------

# OneIteration(Markov, List, Lambda1, Lambda2)
#
# ��  ǽ : ���ַ��������ΰ����η����֤���
#
# ������ : List = [word+, Coef]
#          �������Х��ѿ�: $WordIntStr, @LforWord, $CharIntStr,
#                          $BaseWordIntStr, @BaseLforWord, $BaseWordMarkov

sub OneIteration{
#    warn "OneIteration(...)\n";
    (@_ == 4) || die;
    my($markov, $list, $Lt, $Lb) = @_;

    (%$list > 0) || return($Lt, $Lb);             # Held-out Data ���ʤ�����

    my($Coef_sum, $Lt_new, $Lb_new) = (0, 0, 0);
    while (my($wseq, $Coef) = each(%$list)){
#        printf(STDERR "wseq = %s\n", $wseq);
        my(@word) = split(" ", $wseq);

        my(@stat) = map($WordIntStr->int($_), @word);
        my($Pt) = $Lt*$markov->prob(@stat, @LforWord);
        if ($stat[$MO] == $WordIntStr->int($UT)){ # ̤�θ��ξ���
            $Pt *= exp(-&UWlogP($word[$MO]));
        }

        @stat = map($BaseWordIntStr->int($_), @word);
        my($Pb) = $Lb*$BaseWordMarkov->prob(@stat, @BaseLforWord);
        if ($stat[$MO] == $BaseWordIntStr->int($UT)){ # ̤�θ��ξ���
            $Pb *= exp(-&UWlogP($word[$MO]));
        }

        $Lt_new += $Coef*$Pt/($Pt+$Pb);
        $Lb_new += $Coef*$Pb/($Pt+$Pb);
        $Coef_sum += $Coef;
    }

    $Lt_new /= $Coef_sum;
    $Lb_new /= $Coef_sum;

    my($temp) = 1-($Lt_new+$Lb_new);
    $Lt_new += $temp/2;
    $Lb_new += $temp/2;

    return($Lt_new, $Lb_new);
}


#=====================================================================================
#                        END
#=====================================================================================
