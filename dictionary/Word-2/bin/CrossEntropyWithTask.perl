#!/usr/bin/env perl
#=====================================================================================
#                       CrossEntropyWithTask.perl
#                             bShinsuke Mori
#                             Last change 15 August 2009
#=====================================================================================

# ��  ǽ : ��������ñ��(ɽ��) 2-gram ���Ѥ��� Cross Entropy ���׻����롣
#
# ����ˡ : CrossEntropyWithTask.perl STEP CORPUS
#
# ��  �� : CrossEntropyWithTask.perl 4 corpus/
#
# ������ : ���줾����ñ�� 2-gram ���ǥ�����Ω�ˤ���ɬ�פ�����
#          ���������ǥ����ѿ��ˤ� Task ����Ƭ�����Ѥ��Ƥ���


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

@CharMarkovTest = qw( �� �� );


#-------------------------------------------------------------------------------------
#                        �١����Υ��ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

#($WordIntStr, $WordMarkov, @LforWord) = &Read2gramModel("Word");

#$WordMarkov->test($WordIntStr, @WordMarkovTest);
#warn "\n";

$FILE = "WordIntStr.text";
$WordIntStr = new IntStr($FILE);

$FILE = "TaskWordIntStr.text";
$TaskWordIntStr = new IntStr($FILE);

$TaskCTEMPL = "$TASK/%02d.word";                  # �����������ѥ��Υե�����̾�ο���
$MIN = 2;                                         # ������ʬ�����ѥ���

$LAMBDA = "WithTaskLambda";                       # ���ַ����Υե�����
&CalcLambda($MO, $LAMBDA);
exit(0);

#-------------------------------------------------------------------------------------
#                        ʸ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);

$CharMarkov->test($CharIntStr, @CharMarkovTest);


#-------------------------------------------------------------------------------------
#                        $TaskWordIntStr ������
#-------------------------------------------------------------------------------------

$TaskCTEMPL = "$TASK/%02d.word";                  # �����������ѥ��Υե�����̾�ο���
$MIN = 2;                                         # ������ʬ�����ѥ���

(-e ($FILE = "TaskWordIntStr.text")) ||           # �ե����뤬���뤫��  �ʤ����к���
    &TaskWordIntStr($FILE, map(sprintf($TaskCTEMPL, $_), @Kcross));
$TaskWordIntStr = new IntStr($FILE);


#-------------------------------------------------------------------------------------
#                        $TaskWordMarkov ������
#-------------------------------------------------------------------------------------

if (-e (($FILE = "TaskWordMarkov") . $MarkovHash::SUFFIX)){
    $TaskWordMarkov = new MarkovHashMemo($TaskWordIntStr->size, $FILE);
}else{
    $TaskWordMarkov = new MarkovHashMemo($TaskWordIntStr->size);
#    $TaskWordMarkov = new MarkovHashDisk($TaskWordIntStr->size, "/RAM/$FILE");
    &TaskWordMarkov($TaskWordMarkov, map(sprintf($TaskCTEMPL, $_), @Kcross));
    $TaskWordMarkov->put($FILE);
}
$TaskWordMarkov->test($TaskWordIntStr, @WordMarkovTest);
warn "\n";
exit(0);

#-------------------------------------------------------------------------------------
#                        ��ΨŪñ��ʬ�䥳���ѥ����ǥ���ñ�� 2-gram �����ַ����ο���
#-------------------------------------------------------------------------------------

$LAMBDA = "WithTaskLambda";                       # ���ַ����Υե�����
(-r $LAMBDA) || &CalcLambda($MO, $LAMBDA);        # �ե����뤬�ʤ����з׻�

@LforTask = &ReadLambda($LAMBDA);


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
#        print STDERR join(" ", @word), "\n";
        ($Scur, $Sfol) = map($WordIntStr->int($_), @word);
        ($TaskScur, $TaskSfol) = map($TaskWordIntStr->int($_), @word);

        if ($TaskWordMarkov->_1gram($TaskScur) > 0){
            $prob = $WordMarkov->prob($Scur, $Sfol, @LforTask[0, 1]);
            $taskprob = $TaskWordMarkov->prob($TaskScur, $TaskSfol, @LforTask[2, 3]);
        }else{
            $prob = $WordMarkov->prob($Scur, $Sfol, @LforTask[4, 5]);
            $taskprob = $LforTask[6]*$TaskWordMarkov->_1prob($TaskSfol);
        }
        if ($Sfol == $WordIntStr->int($UT)){      # ̤�θ��ξ���
            $prob *= exp(-&UWlogP($word));        # ̤�θ���ɽ����������Ψ
        }
        $logP += -log($prob+$taskprob);

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
#                        TaskWordIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�������륳���ѥ����ɤ߹��ߡ�ñ���ȿ������б��ط����������롣
#
# ��  �� : WordIntStr.text �Υ����ѡ����å�
#          $MIN �ʾ�����ʬ�����ѥ��Τ˸�����ʸ�����оݤȤ��롣

sub TaskWordIntStr{
    warn "main::WordIntStr\n";
    warn "min = $MIN\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    my(%Freq) = ();                               # ñ�� => ����

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){
#            ($.%$STEP == 0) || next;
            grep($hash{$_} = 0, grep($Freq{$_}++, &Line2Units($_)));
#            grep($hash{$_} = 0, &Line2Units($_));
        }
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    @word = sort {length($b)*$Freq{$b} <=> length($a)*$Freq{$a}} keys(%Freq);

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $WordIntStr->strs()), "\n";
#    foreach $word (sort(keys(%HASH))){
    foreach $word (@word){
#        (length($word)*$Freq{$word} < 2*2*4) && last; # |����|*��ʸ��*�������� MMH
        (length($word)*$Freq{$word} < 2*2*128) && last; # |����|*��ʸ��*�������� MNN
        ($WordIntStr->int($word) eq $WordIntStr->int($UT)) || next;
        ($HASH{$word} >= $MIN) || next;
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
#    foreach $n (@Kcross){                         # ���������ѤΥޥ륳�ե��ǥ�������
#    foreach $n (1,2,3){                         # ���������ѤΥޥ륳�ե��ǥ�������
#    foreach $n (4,5,6){                         # ���������ѤΥޥ륳�ե��ǥ�������
#    foreach $n (7,8,9){                         # ���������ѤΥޥ륳�ե��ǥ�������
    foreach $n (3,6){                         # ���������ѤΥޥ륳�ե��ǥ�������
        $FILE = sprintf("TaskWordMarkov%02d", $n);
        if (-r "$FILE.db"){
            $TaskWordMarkov[$n] = new MarkovHashDisk($WordIntStr->size, $FILE);
        }else{
            $TaskWordMarkov[$n] = new MarkovHashMemo($TaskWordIntStr->size);
            &TaskWordMarkov($TaskWordMarkov[$n],
                            map(sprintf($TaskCTEMPL, $_), grep($_ != $n, @Kcross)));
            $FILE = sprintf("/dev/shm/TaskWordMarkov%02d", $n);
            $TaskWordMarkov[$n]->put($FILE);
            system("/bin/mv $FILE.db .");
        }
        $TaskWordMarkov[$n]->test($TaskWordIntStr, @WordMarkovTest);
        undef($TaskWordMarkov[$n]);
        warn "\n";
    }
    exit(0);

    my(@Tran) = map({}, @Kcross);                 # [(������, ����)+]+
    foreach $n (@Kcross){                         # �����ѥ������������ɤ߹���
        $FILE = sprintf($TaskCTEMPL, $n);
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
#    my(@Lnew) = ((1/4) x 4, (1/3) x 3);           # EM���르�ꥺ���ν�����
    my(@Lnew) = (0.0026, 0.1363, 0.0642, 0.7969, 0.0346, 0.3566, 0.6088); # 2xWWW-St0
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
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforTask[0 .. 3])), "  ";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforTask[4 .. 6])), "\n";
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
#          �������Х��ѿ�: $TaskWordMarkov, $WordIntStr, $WordMarkov, $CharIntStr, $CharMarkov

sub OneIteration{
#    warn "OneIteration(...)\n";
    (@_ == 9) || die;
    my($markov, $list, $L1, $L2, $L3, $L4, $L5, $L6, $L7) = @_;

#    ((@$list > 0) || (@$uwlist > 0))              # Held-out Data ���ʤ�����
#        || return($L1, $L2, $L3, $L4);

    my($wseq, $Wcur, $Wfol, $Scur, $Sfol, $Coef);
    my($p1, $p2, $p3, $p4, $p5, $p6, $p7, $temp);
    my($uwprob);
    my($Coef_sum1, $L1_new, $L2_new, $L3_new, $L4_new) = (0, 0, 0, 0, 0);
    my($Coef_sum2, $L5_new, $L6_new, $L7_new) = (0, 0, 0, 0);
    while (($wseq, $Coef) = each(%$list)){        # ���θ���ͽ¬�Υ�����
        ($Wcur, $Wfol) = split(" ", $wseq);
        ($Scur, $Sfol) = map($WordIntStr->str($_), $Wcur, $Wfol);
        ($TaskScur, $TaskSfol) = map($TaskWordIntStr->int($_), $Wcur, $Wfol);
#        printf(STDERR "%s => %s\n", $Wcur, $Wfol);
        if ($markov->_1gram($TaskScur) > 0){
            $p1 = $L1*$WordMarkov->_1prob($Sfol);
            $p2 = $L2*$WordMarkov->_2prob($Scur, $Sfol);
            if ($Sfol == $WordIntStr->int($UT)){  # ̤�θ��ξ���
                $uwprob = exp(-&UWlogP($Wfol));   # ̤�θ���ɽ����������Ψ
                $p1 *= $uwprob;
                $p2 *= $uwprob;
            }
            $p3 = $L3*$markov->_1prob($TaskSfol);
            $p4 = $L4*$markov->_2prob($TaskScur, $TaskSfol);

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
            $p7 = $L7*$markov->_1prob($TaskSfol);

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


#=====================================================================================
#                        END
#=====================================================================================
