#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       BoundaryAccuracy.perl
#                             bShinsuke Mori
#                             Last change 19 July 2009
#=====================================================================================

# ��  ǽ : ñ��ʬ���Υե��������ɤ߹���ñ�춭�������٤��׻�����
#
# ����ˡ : BoundaryAccuracy.perl (���Ϸ���) (���򥳡��ѥ�) [column]
#
# ��  �� : BoundaryAccuracy.perl EDR10.tagger EDR10.morp 86
#
# ������ : ��ʸ�����Ԥ��б����Ƥ��뤳�ȡ�


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl");

require "Help.pm";
require "Parallel.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

(((@ARGV == 2) || (@ARGV == 3)) && ($ARGV[0] ne "-help")) || &Help($0);

($FILE1, $FILE2) = @ARGV[0, 1];
$COLUMN = (@ARGV == 3) ? $ARGV[2] : defined($COLUMNS) ? $COLUMNS-1 : 86;


#-------------------------------------------------------------------------------------
#                        set variable
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # ��
use constant FAUX => 0;                           # ��

$SEPARE = "-" x ($COLUMN-6) . "\n";


#-------------------------------------------------------------------------------------
#                        initialize
#-------------------------------------------------------------------------------------

open(FILE1) || die "Can't open $FILE1: $!\n";
open(FILE2) || die "Can't open $FILE2: $!\n";


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

$nmt = 0;                                         # FILE1 ��ʸ����
$nmm = 0;                                         # �ޥå����������ǿ�

while ((chop($line1 = <FILE1>)) && (chop($line2 = <FILE2>))){
    @tmp1 = @tmp2 = ();                           # �������ݤ�
#    $line1 =~ s/ \(\d+,\d+\)//;                   # logP �ξõ�
#    $line1 =~ s/ \/UM//g;                   # logP �ξõ�
    $line1 =~ s/\-/ /g;                           # Ϣ�� delimiter ���֤�����
    $line1 =~ s/ [\d\.]+//;                       # logP �ξõ�
    $line2 =~ s/ [\d\.]+//;                       # logP �ξõ�
    @line1 = map((split("/"))[0], split(/[ \t\n]+/, $line1));
    @line2 = map((split("/"))[0], split(/[ \t\n]+/, $line2));
    for ($i = 0; $i < @line1; $i++){
        push(@tmp1, ((FAUX) x (length($line1[$i])/2-1), VRAI));
    }
    for ($i = 0; $i < @line2; $i++){
        push(@tmp2, ((FAUX) x (length($line2[$i])/2-1), VRAI));
    }
#    printf("%d <=> %d\n", scalar(@tmp1), length(join("", @line1))/2);
#    printf("%d <=> %d\n", scalar(@tmp1), scalar(@tmp2));
    (@tmp1 == length(join("", @line1))/2) || die;
    (@tmp2 == length(join("", @line2))/2) || die;
    (@tmp1 == @tmp2) || die;

    for ($i = 0; $i < $#tmp1; $i++){
        $nmt++;
        $nmm++ if ($tmp1[$i] == $tmp2[$i]);
    }
}

printf("��������Ψ = %d/%d = %5.2f%%\n", $nmm, $nmt, 100*$nmm/$nmt);


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

close(FILE1);
close(FILE2);
exit(0);


#=====================================================================================
#                        END
#=====================================================================================
