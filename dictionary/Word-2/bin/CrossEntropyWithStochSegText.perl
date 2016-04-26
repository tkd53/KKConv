#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       CrossEntropyWithStochSegText.perl
#                             bShinsuke Mori
#                             Last change 1 June 2009
#=====================================================================================

# ��  ǽ : ñ�� 2-gram �ȳ�Ψʬ�䥳���ѥ����Ѥ��� Cross Entropy ���׻����롣
#
# ����ˡ : CrossEntropyWithStochSegText.perl (STEP) (STEM) [FILENAME]
#
# ��  �� : CrossEntropyWithSArray.perl 4 ~/SLM/text/mainichi/97
#
# ������ : (STEM).text �� (STEM).sarray �� (STEM).btprob ��ɬ��


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl",
        "$HOME/SLM/text/lib/perl");

require "Help.pm";

require "StochSegText.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

(((@ARGV == 2) || (@ARGV == 3)) && ($ARGV[0] ne "-help")) || &Help($0);

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�
$PATH = shift;
$TEST = (@ARGV) ? shift : undef;

my($STEM) = basename($PATH);


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

@WordMarkovTest = (&Morphs2Words($MorpMarkovTest))[0 .. $MO];


#-------------------------------------------------------------------------------------
#                        $text ������
#-------------------------------------------------------------------------------------

$text = new StochSegText($PATH);

$FILE = $STEM  . ".n-gram";                       # ñ�� n-gram �ե�����(�����å���)
if (-r $FILE){
    printf(STDERR "Reading $FILE ...");
    $text->ReadFCache($FILE);
    printf(STDERR " FcacheSize = %d ... Done\n", $text->FCacheSize);
}


#-------------------------------------------------------------------------------------
#                        ñ��/ʸ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($WordIntStr, $WordMarkov, @LforWord) = &Read2gramModel("Word");
#$WordMarkov->test($WordIntStr, @WordMarkovTest);

($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);
#$CharMarkov->test($CharIntStr, @CharMarkovTest);


#-------------------------------------------------------------------------------------
#                        ��ΨŪñ��ʬ�䥳���ѥ����ǥ� ��ñ�� 2-gram �����ַ����ο���
#-------------------------------------------------------------------------------------

$LAMBDA = $STEM . ".lambda";                      # ���ַ����Υե�����
(-r $LAMBDA) || &CalcLambda($MO, $LAMBDA);        # �ե����뤬�ʤ����з׻�

@LforSSText = &ReadLambda($LAMBDA);


#-------------------------------------------------------------------------------------
#                        �����ȥ��ԡ��η׻�
#-------------------------------------------------------------------------------------

$FLAG = VRAI;                                     # ʸ���Υ�����ɽ��
$FLAG = FAUX;

$CORPUS = $TEST ? $TEST : sprintf($CTEMPL, 10);   # �ƥ��ȥ����ѥ�
open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";
for ($logP = 0, $Cnum = $Wnum = 0; <CORPUS>; ){
    @word = (($BT) x $MO, &Morphs2Words($_), $BT);
    $cnum = scalar(&Morphs2Chars($_))+1;          # ͽ¬�оݤ�ʸ����(ʸ���������ޤ�)
    $wnum = scalar(&Morphs2Words($_))+1;          # ͽ¬�оݤ�ñ����(ʸ���������ޤ�)

    $logp = 0;
    for ($suff = $MO; $suff < @word; $suff++){
        my($Wcur, $Wfol) = @word[$suff-1, $suff];
        my($Scur, $Sfol) = map($WordIntStr->int($_), $Wcur, $Wfol);
        $FLAG && printf(STDERR "%s %s\n", map($WordIntStr->str($_), $Scur, $Sfol));
        $FLAG && printf(STDERR "P(%s => %s) = ??\n", $Wcur, $Wfol);

        if ($text->Freq($Wcur) > 0){              # Fr(wi-1) > 0
            $p1 = $WordMarkov->_1prob($Sfol);
            $p2 = $WordMarkov->_2prob($Scur, $Sfol);
            if ($Sfol == $WordIntStr->int($UT)){  # ̤�θ��ξ���
                $uwprob = exp(-&UWlogP($Wfol));   # ̤�θ���ɽ����������Ψ
                $p1 *= $uwprob;
                $p2 *= $uwprob;
            }
            $p3 = $text->Prob($Wfol);
            $p4 = $text->Prob($Wcur, $Wfol);
            $logp += -log($LforSSText[0]*$p1+$LforSSText[1]*$p2
                         +$LforSSText[2]*$p3+$LforSSText[3]*$p4);
#            $logp += -log(&Summation(map($LforSSText[$_]*$p[$_], (0 .. 3)));
        }else{
            $p5 = $WordMarkov->_1prob($Sfol);
            $p6 = $WordMarkov->_2prob($Scur, $Sfol);
            if ($Sfol == $WordIntStr->int($UT)){  # ̤�θ��ξ���
                $uwprob = exp(-&UWlogP($Wfol));   # ̤�θ���ɽ����������Ψ
                $p5 *= $uwprob;
                $p6 *= $uwprob;
            }
            $p7 = $text->Prob($Wfol);
            $logp += -log($LforSSText[4]*$p5+$LforSSText[5]*$p6+$LforSSText[6]*$p7);
        }
        $FLAG && printf(STDERR "\n");
    }

    $FLAG && printf(STDERR "%s", $_);
    $FLAG && printf(STDERR "  ʸ���� = %d, H = %8.6f\n", $cnum, $logp/$cnum/log(2));
    $FLAG && printf(STDERR "  ñ���� = %d, PP = %8.6f\n\n", $wnum, exp($logp/$wnum));
    $Cnum += $cnum;
    $Wnum += $wnum;
    $logP += $logp;
}
close(CORPUS);

printf(STDERR "ʸ���� = %d, H = %8.6f\n", $Cnum, $logP/$Cnum/log(2));
printf(STDERR "ñ���� = %d, PP = %8.6f\n", $Wnum, exp($logP/$Wnum));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

$FILE = $STEM  . ".n-gram";                       # ñ�� n-gram �ե�����(�����å���)
if (! -r $FILE){
    printf(STDERR "Writing %s, FcacheSize = %d ... ", $FILE, $text->FCacheSize);
    $text->WriteFCache($FILE);
    printf(STDERR "Done\n");
}

exit(0);


#-------------------------------------------------------------------------------------
#                        CalcLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ���ַ����ο���

sub CalcLambda{
    warn "CalcLambda\n";
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե��ǥ��μ���
    my($LAMBDA) = shift;                          # ���ַ����Υե�����̾

    my(@SSText);                                  # �������Х��ǡ��������ѤΥ��ǥ�
    foreach $n (@Kcross){                         # ���������ѤΥޥ륳�ե��ǥ�������
        $SSText[$n] = new StochSegText(sprintf("corpus/%02d", $n));
    }

    my(@Tran) = map({}, @Kcross);                 # [(������, ����)+]+
    foreach $n (@Kcross){                         # �����ѥ������������ɤ߹���
        $FILE = sprintf("corpus/%02d.word", $n);
#        $FILE = sprintf("$CTEMPL", $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){
            @word = (($BT) x $MO, split, $BT);
#            @word = (($BT) x $MO, &Morphs2Words($_), $BT);
            grep(! ${$Tran[$n]}{join(" ", @word[$_-$MO .. $_])}++, ($MO .. $#word));
        }
        close(FILE);
#        while (($key, $val) = each(%{$Tran[$n]})){
#            printf("f(%s) = %d\n", $key, $val);
#        }
    }

    my($TEMPLATE) = "%6.4f";                      # ���ַ��������ӷ���
    my(@Lnew) = ((1/4) x 4, (1/3) x 3);           # EM���르�ꥺ���ν�����
    my(@Lnew) = (0.0037, 0.0313, 0.0466, 0.9183,  0.0370, 0.4474, 0.5156);
                                                  # temp for NLP
    my(@LforSSText);
    do {                                          # EM���르�ꥺ���Υ롼��
        @LforSSText = @Lnew;                  # �����ȥ��å���
        @Lnew = (0) x @LforSSText;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            @Ltmp = &OneIteration($SSText[$n], $Tran[$n], @LforSSText);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforSSText));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforSSText));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforSSText));

    my($FILE) = "> $LAMBDA";                      # ���ַ����ե�����������
    open(FILE, $FILE) || die "Can't open $LAMBDA: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforSSText[0 .. 3])), "  ";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforSSText[4 .. 6])), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        OneIteration
#-------------------------------------------------------------------------------------

# OneIteration(StochSegText, List, Lambda[7])
#
# ��  ǽ : ���ַ��������ΰ����η����֤���
#
# ������ : List = [Wcur, Wfol, Coef]
#          �������Х��ѿ�: $test, $WordIntStr, $WordMarkov, $CharIntStr, $CharMarkov

# BT => �㥫�ꥦ����
# p = (0.000000, 0.000000, 0.000074, -0.000123)

sub OneIteration{
#    warn "OneIteration(...)\n";
    (@_ == 9) || die;
    my($sstext, $list, $L1, $L2, $L3, $L4, $L5, $L6, $L7) = @_;

#    ((@$list > 0) || (@$uwlist > 0))        # Held-out Data ���ʤ�����
#        || return($L1, $L2, $L3, $L4);

    my($wseq, $Wcur, $Wfol, $Scur, $Sfol, $Coef);
    my($p1, $p2, $p3, $p4, $p5, $p6, $p7, $temp);
    my($uwprob);
    my($Coef_sum1, $L1_new, $L2_new, $L3_new, $L4_new) = (0, 0, 0, 0, 0);
    my($Coef_sum2, $L5_new, $L6_new, $L7_new) = (0, 0, 0, 0);
    while (($wseq, $Coef) = each(%$list)){        # ���θ���ͽ¬�Υ�����
        ($Wcur, $Wfol) = split(" ", $wseq);
        ($Scur, $Sfol) = map($WordIntStr->int($_), $Wcur, $Wfol);
#        printf(STDERR "%s => %s\n", $Wcur, $Wfol);
        if ($text->Freq($Wcur)-$sstext->Freq($Wcur) > 0){
            $p1 = $L1*$WordMarkov->_1prob($Sfol);
            $p2 = $L2*$WordMarkov->_2prob($Scur, $Sfol);
            if ($Sfol == $WordIntStr->int($UT)){  # ̤�θ��ξ���
                $uwprob = exp(-&UWlogP($Wfol));   # ̤�θ���ɽ����������Ψ
                $p1 *= $uwprob;
                $p2 *= $uwprob;
            }
            $p3 = $L3*&SSTextProb($text, $sstext, $Wfol);
            $p4 = $L4*&SSTextProb($text, $sstext, $Wcur, $Wfol);
#            printf(STDERR "p = (%f, %f, %f, %f)\n", $p1, $p2, $p3, $p4);

            $L1_new += $Coef*$p1/($p1+$p2+$p3+$p4);
            $L2_new += $Coef*$p2/($p1+$p2+$p3+$p4);
            $L3_new += $Coef*$p3/($p1+$p2+$p3+$p4);
            $L4_new += $Coef*$p4/($p1+$p2+$p3+$p4);
            $Coef_sum1 += $Coef;
        }else{
            $p5 = $L5*$WordMarkov->_1prob($Sfol);
            $p6 = $L6*$WordMarkov->_2prob($Scur, $Sfol);
            if ($Sfol == $WordIntStr->int($UT)){  # ̤�θ��ξ���
                $uwprob = exp(-&UWlogP($Wfol));   # ̤�θ���ɽ����������Ψ
                $p5 *= $uwprob;
                $p6 *= $uwprob;
            }
            $p7 = $L7*&SSTextProb($text, $sstext, $Wfol);
#            printf(STDERR "p = (%f, %f, %f)\n", $p5, $p6, $p7);

            $L5_new += $Coef*$p5/($p5+$p6+$p7);
            $L6_new += $Coef*$p6/($p5+$p6+$p7);
            $L7_new += $Coef*$p7/($p5+$p6+$p7);
            $Coef_sum2 += $Coef;
        }
    }

    $L1_new /= $Coef_sum1;
    $L2_new /= $Coef_sum1;
    $L3_new /= $Coef_sum1;
    $L4_new /= $Coef_sum1;

    $temp = 1-($L1_new+$L2_new+$L3_new+$L4_new);
    $L1_new += $temp/4;
    $L2_new += $temp/4;
    $L3_new += $temp/4;
    $L4_new += $temp/4;

    $L5_new /= $Coef_sum2;
    $L6_new /= $Coef_sum2;
    $L7_new /= $Coef_sum2;

    $temp = 1-($L5_new+$L6_new+$L7_new);
    $L5_new += $temp/3;
    $L6_new += $temp/3;
    $L7_new += $temp/3;

    return($L1_new, $L2_new, $L3_new, $L4_new, $L5_new, $L6_new, $L7_new);
}


#-------------------------------------------------------------------------------------

sub SSTextProb{
    (@_ > 2) || die;
    my($test, $sstext, @word) = @_;

    my($F1) = $text->Freq(@word)-$sstext->Freq(@word);
    pop(@word);
    my($F2) = $text->Freq(@word)-$sstext->Freq(@word);

    return($F1/$F2);
}


#=====================================================================================
#                        END
#=====================================================================================
