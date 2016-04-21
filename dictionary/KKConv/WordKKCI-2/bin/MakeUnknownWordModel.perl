#!/usr/bin/env perl
#=====================================================================================
#                       MakeUnknownWordModel.perl
#                             bShinsuke Mori
#                             Last change 17 September 2012
#=====================================================================================

# ��  ǽ : ��̾�����Ѵ��Ѥ�̤�θ��ǥ�������롣
#
# ����ˡ : MakeUnknownWordModel.perl (STEP)
#
# ��  �� : MakeUnknownWordModel.perl 4
#
# ����� : (filestem).wordkkci �� "ɽ��/���� ..." �ȤʤäƤ��ʤ���Фʤ�ʤ���
#          �Կ��� 4**ARGV[0] �ǳ���ڤ��ʸ�������Ѥ��Ƴؽ����롣


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$TK53HOME/lib/perl");

require "Help.pm";
require "Char.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 1) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ���ؿ���������ɤ߹���
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWordKKCI.perl";
do "dofile/KKConvSetVariables.perl";


#-------------------------------------------------------------------------------------
#                        $WordIntStr ������
#-------------------------------------------------------------------------------------

$MO = 1;                                          # �ޥ륳�ե�ǥ�μ���

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        $KKCIIntStr ������
#-------------------------------------------------------------------------------------

(-e ($FILE = "KKCIIntStr.text")) ||               # �ե����뤬���뤫��  �ʤ���к�롣
    &KKCIIntStr($FILE, map(sprintf($CTEMPL, $_), @Kcross));
$KKCIIntStr = new IntStr($FILE);

$KKCIUT = scalar(@KKCInput)-($KKCIIntStr->size-2);


#-------------------------------------------------------------------------------------
#                        ̤�θ��ɤߥޥ륳�ե�ǥ����ַ����ο���
#-------------------------------------------------------------------------------------

$TEMPLATE = "%6.4f";                              # ��ַ�������ӷ��
$LAMBDA = "KKCILambda";                           # ��ַ����Υե�����
(-r $LAMBDA) && goto LforWNoEst;                  # ���줬�ɤ߹������

foreach $n (@Kcross){                             # �������ѤΥޥ륳�ե�ǥ������
    $KKCIMarkov[$n] = new MarkovHashMemo($KKCIIntStr->size);
    &KKCIMarkov($KKCIMarkov[$n], map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
    $KKCIMarkov[$n]->test($KKCIIntStr, @KKCIMarkovTest);
    warn "\n";
}

foreach $n (@Kcross){                             # �����ѥ��������ɤ߹���
    $FILE = sprintf($CTEMPL, $n);
    open(FILE) || die "Can't open $FILE: $!\n";
    warn "Reading $FILE in Memory\n";
    while (<FILE>){
        ($.%$STEP == 0) || next;
        foreach $unit (&Line2Units($_)){             # [ɽ��/�ɤ�] ñ�̤Υ롼��
            ($word, $kkci) = split("/", $unit);
            ($WordIntStr->int($unit) == $WordIntStr->int($UT)) || next;
            @char = ($kkci =~ m/(..)/g);
#            print join(" ", @char), "\n";
            @stat = map($KKCIIntStr->int($_), ($BT, @char, $BT));
            grep(! $Tran{pack("II", @stat[$_-1, $_])}++, (1 .. $#stat));
        }
    }
    close(FILE);

    $Tran[$n] = [];
    push(@{$Tran[$n]}, [unpack("II", $key), $val]) while (($key, $val) = each(%Tran));
    undef(%Tran);
}

@Lnew = ((1/2) x 2);                              # EM���르�ꥺ��ν����
do {                                              # EM���르�ꥺ��Υ롼��
    @LforKKCI = @Lnew;                            # �����ȥ�å���
    @Lnew = (0) x @LforKKCI;
    foreach $n (@Kcross){                         # k-fold cross validation
        print STDERR $n, " ";
        @Ltmp = $KKCIMarkov[$n]->OneIteration($Tran[$n], @LforKKCI);
        grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforKKCI));
    }
    @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforKKCI));
    printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
} while (! &eq($TEMPLATE, \@Lnew, \@LforKKCI));

undef(@KKCIMarkov);

$FILE = "> $LAMBDA";                              # ��ַ����ե����������
open(FILE) || die "Can't open $FILE: $!\n";
print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforKKCI)), "\n";
close(FILE);

LforWNoEst:

open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
@LforKKCI = map($_+0.0, split(/[ ,]+/, <LAMBDA>));
close(LAMBDA);


#-------------------------------------------------------------------------------------
#                        $KKCIMarkov ������
#-------------------------------------------------------------------------------------

if (-e (($FILE = "KKCIMarkov") . $MarkovHash::SUFFIX)){
    $KKCIMarkov = new MarkovHashDisk($KKCIIntStr->size, $FILE);
}else{
    $KKCIMarkov = new MarkovHashMemo($KKCIIntStr->size);
    &KKCIMarkov($KKCIMarkov, map(sprintf($CTEMPL, $_), @Kcross));
    $KKCIMarkov->put($FILE);
}
$KKCIMarkov->test($KKCIIntStr, @KKCIMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        ����ȥ�ԡ��η׻�
#-------------------------------------------------------------------------------------

$CORPUS = sprintf($CTEMPL, 10);                   # �ƥ��ȥ����ѥ�
open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";
for ($logP = 0, $Tnum = 0; <CORPUS>; ){
    foreach $unit (&Line2Units($_)){             # [ɽ��/�ɤ�] ñ�̤Υ롼��
        ($word, $kkci) = split("/", $unit);
        next unless ($WordIntStr->int($word) == $WordIntStr->int($UT));
        @char = ($kkci =~ m/(..)/g);
        my(@stat) = ($BT) x 1;
        foreach $char (@char, $BT){
            $Tnum++;
            push(@stat, $KKCIIntStr->int($char));
#            printf("F(%s) = %d\n", $char, $KKCIMarkov->_1gram($stat[1]));
            if ($stat[1] != $KKCIIntStr->int($UT)){ # �����ɤߤξ��
#                printf(STDERR "%s\n", $char);
                $logP += $KKCIMarkov->logP(@stat, @LforKKCI);
            }else{                                   # ̤���ɤߤξ��
#                printf(STDERR "UT %s\n", $char);
                $logP += $KKCIMarkov->logP(@stat, @LforKKCI);
                $logP += -log(1/$KKCIUT);
            }
            shift(@stat);
        }
    }
}
close(CORPUS);

printf(STDERR "ʸ���� = %d, H = %8.6f\n", $Tnum, $logP/$Tnum/log(2));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

warn "Done\n";
exit(0);


#-------------------------------------------------------------------------------------
#                        KKCIIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ʸ���ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub KKCIIntStr{
    warn "main::KKCIIntStr\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_), $BT){ # [ɽ��/�ɤ�] ñ�̤Υ롼��
                ($word, $kkci) = split("/", $unit);
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                grep($hash{$_} = 0, ($kkci =~ m/(..)/g));
            }
        }
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, $BT, grep($HASH{$_} >= $MIN, sort(keys(%HASH)))), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        KKCIMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ������ǥ�٥�Υޥ륳�ե�ǥ����������

sub KKCIMarkov{
    warn "main::KKCIMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){     # [ɽ��/�ɤ�] ñ�̤Υ롼��
                ($word, $kkci) = split("/", $unit);
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                @char = ($kkci =~ m/(..)/g);
#                print join(" ", @char), "\n";
                @stat = map($KKCIIntStr->int($_), ($BT, @char, $BT));
                grep(! $markov->inc(@stat[$_-1, $_]), (1 .. $#stat));
            }
        }
        close(CORPUS);
    }

    $markov->inc(($KKCIIntStr->int($UT)) x ($MO+1)); # F(UT) > 0 ���ݾڤ��� (floaring)
}


#=====================================================================================
#                        END
#=====================================================================================
