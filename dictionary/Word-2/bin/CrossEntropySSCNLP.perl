#!/usr/bin/env perl
#=====================================================================================
#                       CrossEntropySSCNLP.perl
#                             bShinsuke Mori
#                             Last change 14 June 2009
#=====================================================================================

# ��  ǽ : ñ�� 2-gram �ȳ�Ψʬ�䥳���ѥ����Ѥ��� Cross Entropy ���׻����롣
#          ����¬����
#
# ����ˡ : CrossEntropySSCNLP.perl (STEP) (FILESTEM) [TEST]
#
# ��  �� : CrossEntropySSCNLP.perl 4 91 ../../corpus/TRL10.morpyomi
#
# ������ : (STEM).text �� (STEM).sarray �� (STEM).btprob ��ɬ��
#
#          ���ַ����η׻��оݤ˹�θ��;�Ϥ���
#          (STEM).sarray ������������ $text �ν�������ɬ��


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

require "StochSegText.pm";
require "class/IntStr.pm";
require "class/MarkovHash.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";


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

(((@ARGV == 2) || (@ARGV == 3)) && ($ARGV[0] ne "-help")) || &Help($0);

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�
$STEM = shift;
$TEST = (@ARGV) ? shift : undef;                  # �ƥ��ȥ����ѥ�

$PATH = dirname($STEM);
$STEM = basename($STEM);


#-------------------------------------------------------------------------------------
#                        ��ͭ���ѿ�������
#-------------------------------------------------------------------------------------

@WordMarkovTest = (&Morphs2Words($MorpMarkovTest))[0 .. 1];


#-------------------------------------------------------------------------------------
#                        $text ������
#-------------------------------------------------------------------------------------

$text = new StochSegText(join("/", $PATH, $STEM));
#$text->printall(200, 215);
#exit(0);

#@SSTextText = qw( �ǣ� �� BT );                # $text �Υƥ���
#$text->test(@SSTextText);


#-------------------------------------------------------------------------------------
#                        ñ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($WordIntStr, $WordMarkov, @LforWord) = &Read2gramModel("Word");
#$WordMarkov->test($WordIntStr, @WordMarkovTest);


#-------------------------------------------------------------------------------------
#                        $RCWordIntStr ������
#-------------------------------------------------------------------------------------

$EXDICT = $PATH . "/" . $STEM . ".cand";          # �ɲä���ñ���Υꥹ��

(-e ($FILE = "RCWordIntStr-" . $STEM . ".text"))
    || &RCWordIntStr($FILE, $WordIntStr, $EXDICT);
#$FILE = "RCWordIntStr-" . $STEM . ".text";
#&RCWordIntStr($FILE, $WordIntStr, $STEM . ".text");

$RCWordIntStr = new IntStr($FILE);
printf(STDERR "%d words are added\n", $RCWordIntStr->size()-$WordIntStr->size());

#die "Done at " , __LINE__, "\n";


#exit(0);                                          # StochSegTextFreq �ˤ���ʬ���ξ���

#$BTFreq = $text->Freq($BT);
#for ($w1 = 1; $w1 < $RCWordIntStr->size(); $w1++){
#    $Freq += $text->Freq($RCWordIntStr->str($w1));
#}
#
#$Freq = 0;
#for ($w1 = 1; $w1 < $RCWordIntStr->size(); $w1++){
#    $Freq += $text->Freq($RCWordIntStr->str($w1), $BT);
#}
#printf("F(BT) - �� F(w,BT) = %f - %f = %f\n", $BTFreq, $Freq, $BTFreq-$Freq);
#exit(0);


#-------------------------------------------------------------------------------------
#                        $RCWordMarkov ������
#-------------------------------------------------------------------------------------

#@RCWordMarkovTest = @WordMarkovTest;
@RCWordMarkovTest = qw( �ң蹳�� �� );

if (-e (($FILE = "RCWordMarkov-" . $STEM) . $MarkovHash::SUFFIX)){
    $RCWordMarkov = new MarkovHashMemo($RCWordIntStr->size, $FILE);
}else{
    $FILE = "/RAM/$FILE";
#    $RCWordMarkov = new MarkovHashMemo($RCWordIntStr->size);
    $RCWordMarkov = new MarkovHashDisk($RCWordIntStr->size, $FILE);
    &RCWordMarkov($RCWordMarkov, $RCWordIntStr, $text);
#    $RCWordMarkov->put($FILE);
}
$RCWordMarkov->test($RCWordIntStr, @RCWordMarkovTest);

#@RCWordMarkovTest = qw( UT BT );
#$RCWordMarkov->test($RCWordIntStr, @RCWordMarkovTest);

die "Done at " , __LINE__, "\n";


#-------------------------------------------------------------------------------------
#                        ʸ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
#$CharUT = $CharAlphabetSize-($CharIntStr->size-2);
#$CharMarkov->test($CharIntStr, @CharMarkovTest);


#-------------------------------------------------------------------------------------
#                        SARRAY �ȷ����ǥޥ륳�ե��ǥ������ַ����ο���
#-------------------------------------------------------------------------------------

$TEMPLATE = "%6.4f";                              # ���ַ��������ӷ���
$LAMBDA = $STEM . ".lambda";                      # ���ַ����Υե�����
(-r $LAMBDA) && goto LforSNoEst;                  # ���줬�ɤ߹���������

foreach $n (@Kcross){                             # ���������ѤΥޥ륳�ե��ǥ�������
    $WordMarkov[$n] = new MarkovHashMemo($WordIntStr->size);
#    $FILE = sprintf("WordMarkov%02d", $n);
#    $WordMarkov[$n] = new MarkovHashDisk($WordIntStr->size, $FILE);
    &WordMarkov($WordMarkov[$n], map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
    $WordMarkov[$n]->test($WordIntStr, @WordMarkovTest);
#    $WordMarkov[$n]->put(sprintf("WordMarkov%02d", $n));
    warn "\n";
}

foreach $n (@Kcross){                             # ���������ѤΥޥ륳�ե��ǥ�������
    $CharMarkov[$n] = new MarkovHashMemo($CharIntStr->size);
    &CharMarkov($CharMarkov[$n], map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
    $CharMarkov[$n]->test($CharIntStr, @CharMarkovTest);
    warn "\n";
}

@Tran = map([], @Kcross);
foreach $n (@Kcross){                             # �����ѥ������������ɤ߹���
    @temp = ();
    $FILE = sprintf($CTEMPL, $n);
    open(FILE) || die "Can't open $FILE: $!\n";
    warn "Reading $FILE in Memory\n";
    while (<FILE>){
        ($.%$STEP == 0) || next;
        @word = ($BT, &Morphs2Words($_), $BT);
        for ($suff = 1; $suff < @word; $suff++){
            $Tran{join(" ", @word[$suff-1, $suff])}++;
        }
    }
    close(FILE);

    $Tran[$n] = [];
    push(@{$Tran[$n]}, [split(" ", $key), $val]) while (($key, $val) = each(%Tran));
    undef(%Tran);
}

@Lnew = ((1/4) x 4, (1/3) x 3);                   # EM���르�ꥺ���ν�����
do {                                              # EM���르�ꥺ���Υ롼��
    @LforWord = @Lnew;                            # �����ȥ��å���
    @Lnew = (0) x @LforWord;
    foreach $n (@Kcross){                         # k-fold cross validation
        print STDERR $n, " ";
        @Ltmp = &OneIteration($WordMarkov[$n], $RCWordMarkov, $CharMarkov[$n],
                              $Tran[$n], @LforWord);
        grep(! ($Lnew[$_] += $Ltmp[$_]), (0..$#LforWord));
    }
    @Lnew = map($Lnew[$_]/scalar(@Kcross), (0..$#LforWord));
    printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
} while (! &eq($TEMPLATE, \@Lnew, \@LforWord));

undef(@WordMarkov);

$FILE = "> $LAMBDA";                              # ���ַ����ե�����������
open(FILE) || die "Can't open $FILE: $!\n";
print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforWord)), "\n";
close(FILE);

LforSNoEst:

open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
@LforWord = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
close(LAMBDA);


#-------------------------------------------------------------------------------------
#                        $WordMarkov ������
#-------------------------------------------------------------------------------------

if (-e (($FILE = "WordMarkov") . $MarkovHash::SUFFIX)){
    $WordMarkov = new MarkovHashMemo($WordIntStr->size, $FILE);
}else{
    $WordMarkov = new MarkovHashMemo($WordIntStr->size);
    &WordMarkov($WordMarkov, map(sprintf($CTEMPL, $_), @Kcross));
    $WordMarkov->put($FILE);
}
$WordMarkov->test($WordIntStr, @WordMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        $CharMarkov ������
#-------------------------------------------------------------------------------------

if (-e (($FILE = "CharMarkov") . $MarkovHash::SUFFIX)){
    $CharMarkov = new MarkovHashMemo($CharIntStr->size, $FILE);
}else{
    $CharMarkov = new MarkovHashMemo($CharIntStr->size);
    &CharMarkov($CharMarkov, map(sprintf($CTEMPL, $_), @Kcross));
    $CharMarkov->put($FILE);
}
$CharMarkov->test($CharIntStr, @CharMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        �����ȥ��ԡ��η׻�
#-------------------------------------------------------------------------------------

$CORPUS = $TEST ? $TEST : sprintf($CTEMPL, 10);   # �ƥ��ȥ����ѥ�
open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";
for ($logP = 0, $Tnum = 0, $Wnum = 0; <CORPUS>; ){
#    warn $_;
#    ($_ eq "-\n") && (print "\n") && next;
    $Tnum += scalar(&Morphs2Chars($_))+1;         # ͽ¬�оݤ�ʸ����(ʸ���������ޤ�)
    $Wnum += scalar(&Morphs2Words($_))+1;         # ñ����
    my($Scur) = $WordIntStr->int($BT);
    my($CRScur) = $RCWordIntStr->int($BT);
    foreach $Wfol (&Morphs2Words($_), $BT){       # ������ñ�̤Υ롼��
        my($dict) = "UM";
        my($CRSfol) = $RCWordIntStr->int($Wfol);
#        if ($Wfol eq "����"){
#            $CRSfol = $UT;
#            warn "Wfol eq ����\n";
#        }
        $dict = "CR" if ($CRSfol != $UT);
        my($Sfol) = $WordIntStr->int($Wfol);
        $dict = "IN" if ($Sfol != $UT);
        if ($RCWordMarkov->_1gram($CRScur) > 0){  # (a) Fr(w0) > 0
            if ($Sfol != $WordIntStr->int($UT)){  # (1) w1 �� InDict
                $p1 = $WordMarkov->_1prob($Sfol);
                $p2 = $WordMarkov->_2prob($Scur, $Sfol);
                $p3 = $RCWordMarkov->_1prob($CRSfol);
                $p4 = $RCWordMarkov->_2prob($CRScur, $CRSfol);
            }else{
                $uwprob = &UWprob($Wfol, $CharMarkov); # Mx(w1)
                if ($CRSfol != $RCWordIntStr->int($UT)){ # (2) w1 �� ExDict
                    $p1 = $uwprob*$WordMarkov->_1prob($Sfol);
                    $p2 = $uwprob*$WordMarkov->_2prob($Scur, $Sfol);
                    $p3 = $RCWordMarkov->_1prob($CRSfol);
                    $p4 = $RCWordMarkov->_2prob($CRScur, $CRSfol);
                }else{                            # (3) w1 !�� ExDict
                    $p1 = $uwprob*$WordMarkov->_1prob($Sfol);
                    $p2 = $uwprob*$WordMarkov->_2prob($Scur, $Sfol);
                    $p3 = $uwprob*$RCWordMarkov->_1prob($CRSfol);
                    $p4 = $uwprob*$RCWordMarkov->_2prob($CRScur, $CRSfol);
                }
            }
            $logP += -log($LforWord[0]*$p1+$LforWord[1]*$p2
                          +$LforWord[2]*$p3+$LforWord[3]*$p4);
        }else{                                    # (b) Fr(w0) == 0
            if ($Sfol != $WordIntStr->int($UT)){  # (1) w1 �� InDict
                $p5 = $WordMarkov->_1prob($Sfol);
                $p6 = $WordMarkov->_2prob($Scur, $Sfol);
                $p7 = $RCWordMarkov->_1prob($CRSfol);
            }else{
                $uwprob = &UWprob($Wfol, $CharMarkov); # Mx(w1)
                if ($CRSfol != $RCWordIntStr->int($UT)){ # (2) w1 �� ExDict
                    $p5 = $uwprob*$WordMarkov->_1prob($Sfol);
                    $p6 = $uwprob*$WordMarkov->_2prob($Scur, $Sfol);
                    $p7 = $RCWordMarkov->_1prob($CRSfol);
                }else{                            # (3) w1 !�� ExDict
                    $p5 = $uwprob*$WordMarkov->_1prob($Sfol);
                    $p6 = $uwprob*$WordMarkov->_2prob($Scur, $Sfol);
                    $p7 = $uwprob*$RCWordMarkov->_1prob($CRSfol);
                }
            }
#            printf(STDERR "%s/%s %7.4f ", $Wfol, $dict,
#                   -log($LforWord[4]*$p5+$LforWord[5]*$p6+$LforWord[6]*$p7));
            $logP += -log($LforWord[4]*$p5+$LforWord[5]*$p6+$LforWord[6]*$p7)
        }
#        printf(STDERR "%s/%s %7.4f ", $Wfol, $dict, $logP/log(2));
        ($Scur, $CRScur) = ($Sfol, $CRSfol);
    } 
#    printf(STDERR "\n");
}
close(CORPUS);

printf(STDERR "ʸ���� = %d, H = %8.6f\n", $Tnum, $logP/$Tnum/log(2));
printf(STDERR "ñ���� = %d, PP = %8.6f\n", $Wnum, exp($logP/$Wnum));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

$text->WriteFCache($STEM . ".n-gram");          # ñ�� n-gram ���٤Υ����å���

exit(0);


#-------------------------------------------------------------------------------------
#                        RCWordIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ��ĥ���ä�����
#
# ������ : �ʤ�

sub RCWordIntStr{
    (@_ == 3) || die;
    my($FILE, $intstr, $TEXT) = @_;

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
#    print join("\n", $intstr->strs), "\n";    # �ʲ��Υ롼�פ��֤�����
    for ($i = 0; $i < $intstr->size; $i++){
        print FILE $intstr->str($i), "\n";
    }

    my(%HASH) = ();
    open(TEXT, $TEXT) || die "Can't open $TEXT: $!\n";
    printf(STDERR "Reading $TEXT ...");
#    printf(STDERR "\n");
    while (chop($sent = <TEXT>)){
        $length = length($sent);
        for ($beg = 0; $beg < $length; $beg += 2){
            for ($len = 2; $beg+$len <= $length; $len += 2){
                $word = substr($sent, $beg, $len);
                ($HASH{$word}) && next;           # ��Ͽ�Ѥ�
                ($intstr->int($word) == $intstr->int($UT)) || next;
                $HASH{$word} = 1;
                print FILE $word, "\n";
#                printf(STDERR "%s\n", $word);
            }
        }
#        last if ($. > 2);
    }
    close(TEXT);
    printf(STDERR " ... Done\n");

    return;
}


#-------------------------------------------------------------------------------------
#                        RCWordMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ñ�� 2-gram ����ɽ�κ���
#
# ������ : ʸñ�̤ǽ���������
# 
#                 ��  ��  ��  ��  ��  5
# $sent =         BT  ��  ��  ��  BT
#                    b1  e1          e2
# 
#             ��������������������������
# $prob[] =   ��P0��P1��P2��P3��P4��P5��
#             ��������������������������
#
#               j
# $pi[$i][$j] = �� Qk      where Qk = (1-Pk)
#               k=i     
#
#           j = 0   1   2   3   4   5
#             ��������������������������
#       i = 0 ������Q1��Qa��Qb��Qc��Qd�� Qa = Q1*Q2, Qb = Q1*Q2*Q3, Qc = Q1*Q2*Q3*Q4
#             ��������������������������
#           1 ����������Q2��Qe��Qf��Qg��             Qe =    Q2*Q3, Qe =    Q2*Q3*Q4
#             ��������������������������
#           2 ��������������Q3��Qh��Qi��                            Qh =       Q3*Q4
#             ��������������������������
#           3 ������������������Q4��Qj��
#             ��������������������������
#           4 ����������������������Q5��
#             ��������������������������
#           5 ��������������������������
#             ��������������������������

sub RCWordMarkov{
    (@_ == 3) || die;
    my($markov, $intstr, $text) = @_;

    my($w1, $w2);                                 # F(w1,w2)

    printf(STDERR "RCWordMarkov(size = %d)\n", $intstr->size());

    for ($offset = 1; $offset < $text->size(); $offset += $suff){
        printf(STDERR "offset = %d (%5.2f%%)\n", $offset, 100*$offset/$text->size());

        my($sent) = $BT;                          # Xi
        my(@prob) = (1.0);                        # Pi
        for ($suff = 0; ; $suff++){
            my($char) = $text->Char($offset+$suff);
            $sent .= $char;
            my($prob) = $text->BTProb($offset+$suff);
            push(@prob, $prob);
            last if ($char eq $BT);
        }
        push(@prob, 1.0);
        $suff++;
#        for ($suff = 0; $suff < @prob; $suff++){
#            printf(STDERR "%02d %11.9f %s\n",
#                   $suff, $prob[$suff], substr($sent, 2*$suff, 2));
#        }
#        print STDERR "sent = ", $sent, "\n";

        (length($sent)/2+1 == scalar(@prob)) || die;
                                                  #           j
        my(@pi) = ([]) x @prob;                   # P[i][j] = ��(1-Pk)
        for ($i = 0; $i < @prob; $i++){           #           k=i
            $pi[$i] = [(1.0) x @prob];
            ($i+1 < @prob) || last;
            $pi[$i][$i+1] = 1-$prob[$i+1];
            for ($j = $i+2; $j < @prob; $j++){
                $pi[$i][$j] = $pi[$i][$j-1]*(1-$prob[$j]);
            }
        }

        for ($beg1 = 0; $beg1 < @prob-2; $beg1++){
            for ($end2 = $beg1+2; $end2 < @prob; $end2++){
                $string = substr($sent, 2*$beg1, 2*($end2-$beg1));
#                printf(STDERR "%s %s %s\n", "-" x 5, $string, "-" x 20);
                for ($end1 = $beg1+1; $end1 < $end2; $end1++){
                    # Ex. (beg1, end1) = (1, 2), (beg2, end2) = (2, 5), 
                    $beg2 = $end1;
                    my($freq) = $prob[$beg1]*$pi[$beg1][$end1-1]*$prob[$end1]
                                            *$pi[$beg2][$end2-1]*$prob[$end2];
                    ($freq > 0) || next;
                    my($w1) = substr($sent, 2*$beg1, 2*($end1-$beg1)); # [beg1, end1)
                    my($w2) = substr($sent, 2*$beg2, 2*($end2-$beg2)); # [beg2, end2)
#                    print STDERR "(", $w1, " ", $w2, ") ";
                    my($suf1) = $intstr->int($w1);
                    my($suf2) = $intstr->int($w2);
                    $markov->add($freq, $suf1, $suf2); # F(w1, w2) += freq;
#                    printf(STDERR "f(%s) += %11.9f\n", $w2, $freq);
#                    printf(STDERR "f(%s, %s) += %11.9f\n", $w1, $w2, $freq);
#                    print STDERR "\n";
                }
            }
#            print STDERR "\n";
        }
#        last if ($offset > 50);
    }
}


#-------------------------------------------------------------------------------------
#                        myeq
#-------------------------------------------------------------------------------------

sub myeq{
    (@_ == 2) || die;

    my($TEMPLATE) = "%20.6f";

    return(sprintf($TEMPLATE, $_[0]) eq sprintf($TEMPLATE, $_[1]));
}


#-------------------------------------------------------------------------------------
#                        WordMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�������륳���ѥ����ɤ߹��ߡ�ñ�����٥��Υޥ륳�ե��ǥ����������롣

sub WordMarkov{
    warn "main::WordMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @state = map($WordIntStr->int($_), ($BT, &Morphs2Words($_), $BT));
            grep(! $markov->inc(@state[$_-1, $_]), (1..$#state)); 
        }
        close(CORPUS);
    }
#    foreach (@Part){
#        $markov->inc(($WordIntStr->int($_)) x 2); # F(UT) > 0 ���ݾڤ��� (floaring)
#    }
}


#-------------------------------------------------------------------------------------
#                        OneIteration
#-------------------------------------------------------------------------------------

# OneIteration(Markov, Markov, Markov, List, Lambda1, Lambda2, Lambda3, Lambda4,
#                                            Lambda5, Lambda6, Lambda7)
#
# ��  ǽ : ���ַ��������ΰ����η����֤���
#
# ������ : List = [Scur, Sfol, Coef]
#          UWList = [word, word]
#          �������Х��ѿ�: &SArrayProb �ط�
#          �ʻ줬���ĤǤʤ��ȿ�����Ψ SArrayProb ������
#          �ʲ��ξ���ʬ��
#
#          (a) Fr(w0) > 0 v.s. (b) Fr(w0) == 0
#
#              (1) w1 �� InDict
#                  P = ��sPs(w1|w0) + ��rPr(w1|w0)
#              (2) w1 !�� InDict �� w1 �� ExDict
#                  P = ��sPs(UT|w0)Mx(w1) + ��rPr(w1|w0)
#              (3) w1 !�� InDict �� w1 !�� ExDict
#                  P = ��sPs(UT|w0)Mx(w1) + ��rPr(UT|w0)Mx(w1)

sub OneIteration{
    (@_ == 11) || die;
#    warn "OneIteration(...)\n";
    my($markov, $crmarkov, $charmarkov, $list, $L1, $L2, $L3, $L4, $L5, $L6, $L7)
        = @_;

    ((@$list > 0) || (@$uwlist > 0))              # Held-out Data ���ʤ�����
        || return($L1, $L2, $L3, $L4, $L5, $L6, $L7);

    my($Scur, $Sfol, $Coef, $Wcur, $Wfol, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $temp);
    my($uwprob);
    my($Coef_sum1, $Coef_sum2) = (0, 0);
    my($L1_new, $L2_new, $L3_new, $L4_new, $L5_new, $L6_new, $L7_new) = (0) x 7;
    foreach $temp (@$list){
        ($Wcur, $Wfol, $Coef) = @$temp;
        ($Scur, $Sfol) = map($WordIntStr->int($_), ($Wcur, $Wfol));
        ($CRScur, $CRSfol) = map($RCWordIntStr->int($_), ($Wcur, $Wfol));
        if ($crmarkov->_1gram($Scur) > 0){        # (a) Fr(w0) > 0
            if ($Sfol != $WordIntStr->int($UT)){  # (1) w1 �� InDict
                $p1 = $L1*$markov->_1prob($Sfol);
                $p2 = $L2*$markov->_2prob($Scur, $Sfol);
                $p3 = $L3*$crmarkov->_1prob($Sfol);
                $p4 = $L4*$crmarkov->_2prob($Scur, $Sfol);
            }else{
                $uwprob = &UWprob($Wfol, $charmarkov); # Mx(w1)
                if ($CRSfol != $RCWordIntStr->int($UT)){ # (2) w1 �� ExDict
                    $p1 = $uwprob*$L1*$markov->_1prob($Sfol);
                    $p2 = $uwprob*$L2*$markov->_2prob($Scur, $Sfol);
                    $p3 = $L3*$crmarkov->_1prob($Sfol);
                    $p4 = $L4*$crmarkov->_2prob($Scur, $Sfol);
                }else{                            # (3) w1 !�� ExDict
                    $p1 = $uwprob*$L1*$markov->_1prob($Sfol);
                    $p2 = $uwprob*$L2*$markov->_2prob($Scur, $Sfol);
                    $p3 = $uwprob*$L3*$crmarkov->_1prob($Sfol);
                    $p4 = $uwprob*$L4*$crmarkov->_2prob($Scur, $Sfol);
                }
            }
            $L1_new += $Coef*$p1/($p1+$p2+$p3+$p4);
            $L2_new += $Coef*$p2/($p1+$p2+$p3+$p4);
            $L3_new += $Coef*$p3/($p1+$p2+$p3+$p4);
            $L4_new += $Coef*$p4/($p1+$p2+$p3+$p4);
            $Coef_sum1 += $Coef;
        }else{                                    # (b) Fr(w0) == 0
            if ($Sfol != $WordIntStr->int($UT)){  # (1) w1 �� InDict
                $p5 = $L5*$markov->_1prob($Sfol);
                $p6 = $L6*$markov->_2prob($Scur, $Sfol);
                $p7 = $L7*$crmarkov->_1prob($Sfol);
            }else{
                $uwprob = &UWprob($Wfol, $charmarkov); # Mx(w1)
                if ($CRSfol != $RCWordIntStr->int($UT)){ # (2) w1 �� ExDict
                    $p5 = $uwprob*$L5*$markov->_1prob($Sfol);
                    $p6 = $uwprob*$L6*$markov->_2prob($Scur, $Sfol);
                    $p7 = $L7*$crmarkov->_1prob($Sfol);
                }else{                            # (3) w1 !�� ExDict
                    $p5 = $uwprob*$L5*$markov->_1prob($Sfol);
                    $p6 = $uwprob*$L6*$markov->_2prob($Scur, $Sfol);
                    $p7 = $uwprob*$L7*$crmarkov->_1prob($Sfol);
                }
            }
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

    if ($Coef_sum2 > 0){
        $L5_new /= $Coef_sum2;
        $L6_new /= $Coef_sum2;
        $L7_new /= $Coef_sum2;

        $temp = 1-($L5_new+$L6_new+$L7_new);
        $L5_new += $temp/3;
        $L6_new += $temp/3;
        $L7_new += $temp/3;
    }else{
        ($L5_new, $L6_new, $L7_new) = ($L5, $L6, $L7);
    }

    return($L1_new, $L2_new, $L3_new, $L4_new, $L5_new, $L6_new, $L7_new);
}


#-------------------------------------------------------------------------------------
#                        UWprob
#-------------------------------------------------------------------------------------

sub UWprob{
    (@_ == 2) || die;
    my($word, $markov) = (shift, shift);

    my($logP) = 0;
    my(@char) = ($CharIntStr->int($BT)) x 1;
    foreach ($word =~ m/(..)/g, $BT){              # ʸ��ñ�̤Υ롼��
        push(@char, $CharIntStr->int($_));
        $logP += -log($markov->prob(@char, @LforChar));
        $logP += log($CharUT) if ($char[1] == $CharIntStr->int($UT));
        shift(@char);
    }
    
    return(exp(-$logP));
}


#-------------------------------------------------------------------------------------
#                        TestText
#-------------------------------------------------------------------------------------

# ��  ǽ : StochSegText �Υƥ���
#
# ������ : �����ɤ���¸���뤿��

sub TestText(){
    my(@word);

    @word = qw( �ȥ� �Բ� �� ���� );
    @word = qw( ���� �� ���� );

    @word = qw( �Τ� ������ );
    $freq = $text->Freq(@word);
    printf("F(%s) = %f\n", join(" ", @word), $freq);

    pop(@word);
    $freq = $text->Freq(@word);
    printf("F(%s) = %f\n", join(" ", @word), $freq);

    pop(@word);
    $freq = $text->Freq(@word);
    printf("F(%s) = %f\n", join(" ", @word), $freq);

#    $prob = $text->Prob(@word);
#    printf("P(%s) = %f\n", join(" ", @word), $prob);
}


#=====================================================================================
#                        END
#=====================================================================================
