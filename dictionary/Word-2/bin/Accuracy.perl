#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       Accuracy.perl
#                             bShinsuke Mori
#                             Last change 15 August 2014
#=====================================================================================

# 機  能 : 形態素列のファイルを読み込み適合率と再現率を計算する。
#
# 使用法 : Accuracy.perl (解析結果) (正解コーパス) [column]
#
# 実  例 : Accuracy.perl EDR10.tagger EDR10.morp 86
#
# 注意点 : 一文が一行に対応していること。


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$TKD53HOME/lib/perl");

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

$SEPARE = "-" x ($COLUMN-6) . "\n";


#-------------------------------------------------------------------------------------
#                        initialize
#-------------------------------------------------------------------------------------

open(FILE1) || die "Can't open $FILE1: $!\n";
open(FILE2) || die "Can't open $FILE2: $!\n";


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

$suc = 0;                                         # マッチした文数
$nm1 = 0;                                         # FILE1 の形態素数
$nm2 = 0;                                         # FILE2 の形態素数
$nmm = 0;                                         # マッチした形態素数

for ($num = 0; (chop($line1 = <FILE1>)) && (chop($line2 = <FILE2>)); $num++){
    @tmp1 = @tmp2 = ();                           # 出力用のテンポラリ
    $line1 =~ s/\-/ /g;                           # 連語 delimiter の置き換え
    $line1 =~ s/ [\d\.]+//;                       # logP の消去
    $line2 =~ s/ [\d\.]+//;                       # logP の消去
    $nm1 += scalar(@line1 = map((split("/"))[0], split(/[ \t\n]+/, $line1)));
    $nm2 += scalar(@line2 = map((split("/"))[0], split(/[ \t\n]+/, $line2)));
    $line1 = join(" ", @line1);
    $line2 = join(" ", @line2);
    for ($pos1 = $pos2 = 0; @line1 || @line2; ){  # 各形態素の比較
        if ($pos1 < $pos2){
            $word1 = shift(@line1);
            $pos1 += length($word1);
            push(@tmp1, $word1);
            next;
        }
        if ($pos1 > $pos2){
            $word2 = shift(@line2);
            $pos2 += length($word2);
            push(@tmp2, $word2);
            next;
        }
        if ($pos1 == $pos2){
            $word1 = shift(@line1);
            $word2 = shift(@line2);
            $pos1 += length($word1);
            $pos2 += length($word2);
            if ($word1 eq $word2){
                $nmm++;
                push(@tmp1, $word1);
                push(@tmp2, " " x (length($word2)));
            }else{
                push(@tmp1, $word1);
                push(@tmp2, $word2);
            }
            next;
        }
        die;                                      # ここには絶対に到達できない!!
    }
    if ($line1 ne $line2){
        printf("%5d %s", $., $SEPARE);
        parallel($COLUMN, \@tmp1, \@tmp2);
    }else{
        $suc++;
    }
    (@line1 == @line2) || die;
}

$FILE1 = basename($FILE1);
$FILE2 = basename($FILE2);
#printf("Intersection/%s = %d/%d = %5.2f%%\n", $FILE1, $nmm, $nm1, 100*$nmm/$nm1);
#printf("Intersection/%s = %d/%d = %5.2f%%\n", $FILE2, $nmm, $nm2, 100*$nmm/$nm2);
#printf("F(β=1) = %5.2f\n", 100/((1/($nmm/$nm1)+1/($nmm/$nm2))/2));
#printf("文正解率 = %d/%d = %5.2f%%\n", $suc, $num, 100*$suc/$num);
#printf(STDERR "Intersection/%s = %d/%d = %5.2f%%\n", $FILE1, $nmm, $nm1, 100*$nmm/$nm1);
#printf(STDERR "Intersection/%s = %d/%d = %5.2f%%\n", $FILE2, $nmm, $nm2, 100*$nmm/$nm2);
#printf(STDERR "F(β=1) = %5.2f\n", 100/((1/($nmm/$nm1)+1/($nmm/$nm2))/2));
#printf(STDERR "文正解率 = %d/%d = %5.2f%%\n", $suc, $num, 100*$suc/$num);


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

close(FILE1);
close(FILE2);
exit(0);


#=====================================================================================
#                        END
#=====================================================================================
