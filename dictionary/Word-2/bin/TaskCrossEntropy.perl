#!/usr/bin/env perl
#=====================================================================================
#                       TaskCrossEntropy.perl
#                             bShinsuke Mori
#                             Last change 12 October 2014
#=====================================================================================

# ��  ǽ : ��������ñ��(ɽ��) 2-gram ���Ѥ��� Cross Entropy ���׻����롣
#
# ����ˡ : CrossEntropyWithTask.perl (STEP) (CORPUS)
#
# ��  �� : CrossEntropyWithTask.perl 4 corpus/
#
# ������ : ���줾����ñ�� 2-gram ���ǥ�����Ω�ˤ���ɬ�פ�����
#          ���������ǥ����ѿ��ˤ� Task ����Ƭ�����Ѥ��Ƥ���
#
# How To : 1) �ǥ��쥯�ȥ� $DIRE �κ��� (ex. $DIRE = 1xMNN-Step0)
#               mkdir $DIRE; cd $DIRE
#          2) �١����Ȥʤ��������ǥ��ؤΥ��󥯤κ���
#               MakeLink.csh 0
#          3) ������ΨŪñ��ʬ�䥳���ѥ��κ���
#               mkdir corpus; MonteCarlo.perl?? (STEM) | split.perl %02d.word 9
#          4) ���ä����ַ����ο����ȥ��ǥ��κ���
#               ../bin/TaskCrossEntropy.perl 0 corpus
#             ���������� $Freq �ˤ������ÿ���Ĵ��
#               �����ѥ� $TaskCTEMPL �ˤ���Ŭ���оݤ��ѹ�


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use English;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl");

require "Help.pm";
require "Char.pm";
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
print STDERR join(":", $HOST, $PID), "\n";

$STEP = 4**shift;
$TASK = shift;                                    # �������θ������ǥ��Υѥ�
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

@WordMarkovTest = (&Line2Units($WordMarkovTest))[0 .. $MO];

$TaskSTEP = 1;                                    # Ŭ���оݥ����ѥ��δְ���


#-------------------------------------------------------------------------------------
#                        ñ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($WordIntStr, $WordMarkov, @LforWord) = &Read2gramModel("Word");
#$WordMarkov->test($WordIntStr, @WordMarkovTest);


#-------------------------------------------------------------------------------------
#                        ʸ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);

#$CharMarkov->test($CharIntStr, @CharMarkovTest);


#-------------------------------------------------------------------------------------
#                        $TaskWordIntStr ������
#-------------------------------------------------------------------------------------

$TaskCTEMPL = "$TASK/%02d.word";                  # �����������ѥ��Υե�����̾�ο���
$MIN = 2;                                         # ������ʬ�����ѥ���

(-e ($FILE = "TaskWordIntStr.text")) ||           # �ե����뤬���뤫��  �ʤ����к���
    &TaskWordIntStr($FILE, map(sprintf($TaskCTEMPL, $_), @Kcross));
$TaskWordIntStr = new IntStr($FILE);

#$TaskSTEP = 2**8;                                    # Ŭ���оݥ����ѥ��δְ���
#$TaskSTEP = 2**4;                                    # Ŭ���оݥ����ѥ��δְ���
#$TaskSTEP = 2**1;                                    # Ŭ���оݥ����ѥ��δְ���
#$TaskSTEP = 2**1;                                    # Ŭ���оݥ����ѥ��δְ���
#$TaskSTEP = 2**0;                                    # Ŭ���оݥ����ѥ��δְ���
$TaskCTEMPL = "../../../corpus/%02d.word";           # �����������ѥ��Υե�����̾�ο���
$LAMBDA = "B-TaskWordLambda";                       # ���ַ����Υե�����
#$LAMBDA = "T-TaskWordLambda";                       # ���ַ����Υե�����
#$LAMBDA = "TaskWordLambda";                       # ���ַ����Υե�����
(-r $LAMBDA) || &CalcLambda($MO, $LAMBDA);        # �ե����뤬�ʤ����з׻�
#exit(0);


#-------------------------------------------------------------------------------------
#                        $TaskWordMarkov ������
#-------------------------------------------------------------------------------------

if (-e (($FILE = "TaskWordMarkov") . $MarkovHash::SUFFIX)){
    $TaskWordMarkov = new MarkovHashMemo($TaskWordIntStr->size, $FILE);
}else{
    $TaskWordMarkov = new MarkovHashMemo($TaskWordIntStr->size);
#    $TaskWordMarkov = new MarkovHashDisk($TaskWordIntStr->size, "/RAM/$FILE");
    &TaskWordMarkov($TaskWordMarkov, map(sprintf($TaskCTEMPL, $_), @Kcross));
#    $TaskWordMarkov->put($FILE);
    $TaskWordMarkov->put("/dev/shm/$FILE");
    system("/bin/mv /dev/shm/$FILE.db .");
}
$TaskWordMarkov->test($TaskWordIntStr, @WordMarkovTest);
warn "\n";
#exit(0);


#-------------------------------------------------------------------------------------
#                        ��ΨŪñ��ʬ�䥳���ѥ����ǥ��ȥ��饹 2-gram �����ַ����ο���
#-------------------------------------------------------------------------------------

$LAMBDA = "TaskWordLambda";                       # ���ַ����Υե�����
(-r $LAMBDA) || &CalcLambda($MO, $LAMBDA);        # �ե����뤬�ʤ����з׻�

@LforTask = &ReadLambda($LAMBDA);


#-------------------------------------------------------------------------------------
#                        �����ȥ��ԡ��η׻�
#-------------------------------------------------------------------------------------

$FLAG = VRAI;                                     # ʸ���Υ�����ɽ��
$FLAG = FAUX;

(scalar(@LforTask) == 5) || die;
($L1, $L2, $L3, $L4, $L5) = @LforTask;

$CORPUS = $TEST ? $TEST : sprintf($CTEMPL, 10);   # �ƥ��ȥ����ѥ�
open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";

for ($logP = 0, $Cnum = 0, $Wnum = 0; <CORPUS>; ){
    $Cnum += scalar(&Line2Chars($_))+1;
    $Wnum += scalar(&Line2Units($_))+1;

    my(@word) = ($BT) x $MO;
    foreach $word (&Line2Units($_), $BT){         # ñ��ñ�̤Υ롼��
        push(@word, $word);
#        print STDERR join(" ", @word), "\n";
        ($Scur, $Sfol) = map($WordIntStr->int($_), @word);
        ($TaskScur, $TaskSfol) = map($TaskWordIntStr->int($_), @word);
        if ($TaskWordMarkov->_1gram($TaskScur) > 0){
            $p1 = $L1*$WordMarkov->prob($Scur, $Sfol, @LforWord);
            if ($TaskSfol != $TaskWordIntStr->int($UT)){ # ��������̤�θ��Ǥʤ���
                if ($Sfol == $WordIntStr->int($UT)){ # �١�����̤�θ��ξ���
                    $p1 *= exp(-&UWlogP($word)); # ̤�θ���ɽ����������Ψ
                }
                $UwLogP = 0;
            }else{
                $UwLogP = &UWlogP($word);
            }
            $p2 = $L2*$TaskWordMarkov->_1prob($TaskSfol);
            $p3 = $L3*$TaskWordMarkov->_2prob($TaskScur, $TaskSfol);
            $logP += -log($p1+$p2+$p3)+$UwLogP;
        }else{
            $p4 = $L4*$WordMarkov->prob($Scur, $Sfol, @LforWord);
            if ($TaskSfol != $TaskWordIntStr->int($UT)){
                if ($Sfol == $WordIntStr->int($UT)){ # ̤�θ��ξ���
                    $p4 *= exp(-&UWlogP($Wfol)); # ̤�θ���ɽ����������Ψ
                }
                $UwLogP = 0;
            }else{
                $UwLogP = &UWlogP($word);
            }
            my($p5) = $L5*$TaskWordMarkov->_1prob($TaskSfol);
            $logP += -log($p4+$p5)+$UwLogP;
        }
        shift(@word);
    }
}
close(CORPUS);

printf(STDERR "ʸ���� = %d, H = %8.6f\n", $Cnum, $logP/$Cnum/log(2));
printf(STDERR "ñ���� = %d, PP = %8.6f\n", $Wnum, exp($logP/$Wnum));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#-------------------------------------------------------------------------------------
#                        TaskWordIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�������륳���ѥ����ɤ߹��ߡ�ñ���ȿ������б��ط����������롣
#
# ��  �� : WordIntStr.text �Υ����ѡ����å�
#          $MIN �ʾ�����ʬ�����ѥ��Τ˸�����ʸ�����оݤȤ��롣

sub TaskWordIntStr{
    warn "main::TaskWordIntStr(MIN = $MIN)\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    my(%Freq) = ();                               # ñ�� => ����

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){
            ($.%$TaskSTEP == 0) || next;
#            grep($hash{$_} = 0, &Line2Units($_));
            grep($hash{$_} = 0, grep($Freq{$_}++, &Line2Units($_)));
        }
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    @word = sort {length($b)*$Freq{$b} <=> length($a)*$Freq{$a}} keys(%Freq);

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $WordIntStr->strs()), "\n";
#    foreach $word (sort(keys(%HASH))){
#    my($Freq) = 16;                                # �������� 8xWMA
#    my($Freq) = 8;                                # �������� 8xWMA
    my($Freq) = 2;                                # �������� 2xNLP
#    my($Freq) = 1;                                # �������� 8xMPT
#    my($Freq) = 1;                                # �������� 1xMMH
#    my($Freq) = 4;                                # �������� 8xMMH
#    my($Freq) = 128;                              # �������� 1xMNN, 1xWWW
#    my($Freq) = 32;                              # �������� 1xWWW
    foreach $word (@word){
        (length($word)*$Freq{$word} < 2*2*$Freq) && last; # |����|*��ʸ��*��������
        ($WordIntStr->int($word) eq $WordIntStr->int($UT)) || next;
        ($HASH{$word} >= $MIN) || next;
        my(@char) = ($word =~ m/(..)/g);
        grep($SIGN{$_}, @char) && next;           # @SIGN ���ޤޤʤ�
        grep($NUMBER{$_}, @char) && next;         # @NUMBER ���ޤޤʤ�
        grep($LATIND{$_}, @char) && next;         # @LATIND ���ޤޤʤ�
        grep($GREEKU{$_}, @char) && next;         # @ ���ޤޤʤ�
        grep($GREEKD{$_}, @char) && next;         # @ ���ޤޤʤ�
        grep($CYRILU{$_}, @char) && next;         # @ ���ޤޤʤ�
        grep($CYRILD{$_}, @char) && next;         # @ ���ޤޤʤ�

        print FILE $word, "\n";
    }
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        TaskWordMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�������륳���ѥ����ɤ߹��ߡ�ñ�����٥��Υޥ륳�ե��ǥ����������롣

sub TaskWordMarkov{
    warn "main::TaskWordMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$TaskSTEP == 0) || next;
            @stat = map($TaskWordIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat));
        }
        close(CORPUS);
    }
}


#-------------------------------------------------------------------------------------
#                        CalcLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ���ַ����ο���
#
# ����ˡ :
#
# ��  �� :
#
# ������ : referring to $TaskWordIntStr, $TaskCTEMPL,

sub CalcLambda{
    warn "CalcLambda\n";
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե��ǥ��μ���
    my($LAMBDA) = shift;                          # ���ַ����Υե�����̾

    my(@WordMarkov);                              # �������Х��ǡ��������ѤΥ��ǥ�
    foreach $n (@Kcross){                         # ���������ѤΥޥ륳�ե��ǥ�������
#    foreach $n (1,2,3){                         # ���������ѤΥޥ륳�ե��ǥ�������
#    foreach $n (4,5,6){                         # ���������ѤΥޥ륳�ե��ǥ�������
#    foreach $n (7,8,9){                         # ���������ѤΥޥ륳�ե��ǥ�������
        $FILE = sprintf("TaskWordMarkov%02d", $n);
        if (-r "$FILE.db"){
            $TaskWordMarkov[$n] = new MarkovHashDisk($WordIntStr->size, $FILE);
        }else{
            $TaskWordMarkov[$n] = new MarkovHashMemo($TaskWordIntStr->size);
            &TaskWordMarkov($TaskWordMarkov[$n],
                            map(sprintf($TaskCTEMPL, $_), grep($_ != $n, @Kcross)));
#            $FILE = sprintf("/RAM/TaskWordMarkov%02d", $n);
            $FILE = sprintf("/dev/shm/TaskWordMarkov%02d", $n);
            $TaskWordMarkov[$n]->put($FILE);
            system("/bin/mv $FILE.db .");
        }
        $TaskWordMarkov[$n]->test($TaskWordIntStr, @WordMarkovTest);
#        undef($TaskWordMarkov[$n]);
        warn "\n";
    }
#    exit(0);

    my(@Tran);                                    # [(������, ����)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack �� TEMPLATE
    foreach $n (@Kcross){                         # �����ѥ������������ɤ߹���
        $FILE = sprintf($TaskCTEMPL, $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){
            ($.%$TaskSTEP == 0) || next;
            @stat = map($TaskWordIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
            grep(! $Tran{pack($PT, @stat[$_-$MO .. $_])}++, ($MO .. $#stat));
        }
        close(FILE);

        $Tran[$n] = [];
        while (($key, $val) = each(%Tran)){
            push(@{$Tran[$n]}, [unpack($PT, $key), $val]);
        }
        undef(%Tran);
    }

    my($TEMPLATE) = "%6.4f";                      # ���ַ��������ӷ���
#    my(@Lnew) = ((1/4) x 3, (1/3) x 2);           # EM���르�ꥺ���ν�����
#    my(@Lnew) = (0.9420, 0.0011, 0.0569, 0.9999, 0.0001); # 1xWWW for B
#    my(@Lnew) = (0.9950, 0.0001, 0.0049, 1.0000, 0.0000); # 1xMPT for B
#    my(@Lnew) = (0.080, 0.007, 0.913, 0.4144, 0.5856); # w/o unidic 1xMNN for T
#    my(@Lnew) = (0.0063, 0.0076, 0.9861, 0.6602, 0.3398); # 8xWMA for T
#    my(@Lnew) = (0.9974, 0.0001, 0.0025, 0.9999, 0.0001); # 8xWMA for B
#    my(@Lnew) = (0.7130, 0.2367, 1-0.7130-0.2367, 0.3434, 0.6566); # 2xWMA for T
    my(@Lnew) = (0.9519, 0.000001, 0.04821, 0.8142, 0.1858); # 2xWMA for B

    my(@LforTask);
    do {                                          # EM���르�ꥺ���Υ롼��
        @LforTask = @Lnew;                        # �����ȥ��å���
        @Lnew = (0) x @LforTask;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            @Ltmp = &OneIteration($TaskWordMarkov[$n], $Tran[$n], @LforTask);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforTask));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforTask));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforTask));

    my($FILE) = "> $LAMBDA";                      # ���ַ����ե�����������
    open(FILE, $FILE) || die "Can't open $LAMBDA: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforTask[0 .. 2])), "  ";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforTask[3 .. 4])), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        OneIteration
#-------------------------------------------------------------------------------------

# OneIteration(StochSegText, List, Lambda[5])
#
# ��  ǽ : ���ַ��������ΰ����η����֤�
#
# ������ : List = [TaskScur, TaskSfol, Coef]
#          �������Х��ѿ�: $TaskWordIntStr, $TaskWordMarkov,
#                          $WordIntStr, $WordMarkov,
#                          $CharIntStr, $CharMarkov

sub OneIteration{
#    warn "OneIteration(...)\n";
    (@_ == 7) || die;
    my($markov, $list, $L1, $L2, $L3, $L4, $L5) = @_;

    my($Coef_sum1, $L1_new, $L2_new, $L3_new) = (0, 0, 0, 0);
    my($Coef_sum2, $L4_new, $L5_new) = (0, 0, 0);
    foreach (@$list){
        my($TaskScur, $TaskSfol, $Coef) = @$_;
        my($Wcur, $Wfol) = map($TaskWordIntStr->str($_), ($TaskScur, $TaskSfol));
        my($Scur, $Sfol) = map($WordIntStr->int($_), ($Wcur, $Wfol));
#        printf(STDERR "%s => %s\n", $Wcur, $Wfol);

        if ($markov->_1gram($TaskScur) > 0){      # ñ�� 2-gram ��Ψ�������Ǥʤ�����
            my($p1) = $L1*$WordMarkov->prob($Scur, $Sfol, @LforWord);
            if ($TaskSfol != $TaskWordIntStr->int($UT)){ # ��������̤�θ��Ǥʤ���
                if ($Sfol == $WordIntStr->int($UT)){     # �١�����̤�θ��ξ���
                    $p1 *= exp(-&UWlogP($Wfol));         #   ̤�θ���ɽ����������Ψ
                }
            }
            my($p2) = $L2*$markov->_1prob($TaskSfol);
            my($p3) = $L3*$markov->_2prob($TaskScur, $TaskSfol);

            $L1_new += $Coef*$p1/($p1+$p2+$p3);
            $L2_new += $Coef*$p2/($p1+$p2+$p3);
            $L3_new += $Coef*$p3/($p1+$p2+$p3);
            $Coef_sum1 += $Coef;
        }else{                                    # ñ�� 2-gram ��Ψ�������Ǥ�������
            my($p4) = $L4*$WordMarkov->prob($Scur, $Sfol, @LforWord);
            if ($TaskSfol != $TaskWordIntStr->int($UT)){ # ��������̤�θ��Ǥʤ���
                if ($Sfol == $WordIntStr->int($UT)){     # ̤�θ��ξ���
                    $p4 *= exp(-&UWlogP($Wfol));         #   ̤�θ���ɽ����������Ψ
                }
            }
            my($p5) = $L5*$markov->_1prob($TaskSfol);

            $L4_new += $Coef*$p4/($p4+$p5);
            $L5_new += $Coef*$p5/($p4+$p5);
            $Coef_sum2 += $Coef;
        }
    }

    my($temp);

    $L1_new /= $Coef_sum1;
    $L2_new /= $Coef_sum1;
    $L3_new /= $Coef_sum1;

    $temp = 1-($L1_new+$L2_new+$L3_new);
    $L1_new += $temp/3;
    $L2_new += $temp/3;
    $L3_new += $temp/3;

    $L4_new /= $Coef_sum2;
    $L5_new /= $Coef_sum2;

    $temp = 1-($L4_new+$L5_new);
    $L4_new += $temp/2;
    $L5_new += $temp/2;

# Base = 0.25 fix!!
#    $L1_new = $L4_new = 0.25;
#    $L2_new = (1-$L1_new)*$L2_new/($L2_new+$L3_new);
#    $L3_new = (1-$L1_new)*$L3_new/($L2_new+$L3_new);
#    $L5_new = (1-$L4_new);

    return($L1_new, $L2_new, $L3_new, $L4_new, $L5_new);
}


#=====================================================================================
#                        END
#=====================================================================================
