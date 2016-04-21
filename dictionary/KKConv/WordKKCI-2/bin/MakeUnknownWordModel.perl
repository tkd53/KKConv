#!/usr/bin/env perl
#=====================================================================================
#                       MakeUnknownWordModel.perl
#                             bShinsuke Mori
#                             Last change 17 September 2012
#=====================================================================================

# 機  能 : 仮名漢字変換用の未知語モデルを構成する。
#
# 使用法 : MakeUnknownWordModel.perl (STEP)
#
# 実  例 : MakeUnknownWordModel.perl 4
#
# 注意点 : (filestem).wordkkci は "表記/入力 ..." となっていなければならない。
#          行数が 4**ARGV[0] で割り切れる文だけを用いて学習する。


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

$STEP = 4**shift;                                 # 学習コーパスの文のステップ


#-------------------------------------------------------------------------------------
#                        共通の変数や関数の定義を読み込む
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWordKKCI.perl";
do "dofile/KKConvSetVariables.perl";


#-------------------------------------------------------------------------------------
#                        $WordIntStr の生成
#-------------------------------------------------------------------------------------

$MO = 1;                                          # マルコフモデルの次数

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        $KKCIIntStr の生成
#-------------------------------------------------------------------------------------

(-e ($FILE = "KKCIIntStr.text")) ||               # ファイルがあるか？  なければ作る。
    &KKCIIntStr($FILE, map(sprintf($CTEMPL, $_), @Kcross));
$KKCIIntStr = new IntStr($FILE);

$KKCIUT = scalar(@KKCInput)-($KKCIIntStr->size-2);


#-------------------------------------------------------------------------------------
#                        未知語読みマルコフモデルの補間係数の推定
#-------------------------------------------------------------------------------------

$TEMPLATE = "%6.4f";                              # 補間係数の比較桁数
$LAMBDA = "KKCILambda";                           # 補間係数のファイル
(-r $LAMBDA) && goto LforWNoEst;                  # これが読み込める場合

foreach $n (@Kcross){                             # 削除補間用のマルコフモデルの生成
    $KKCIMarkov[$n] = new MarkovHashMemo($KKCIIntStr->size);
    &KKCIMarkov($KKCIMarkov[$n], map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
    $KKCIMarkov[$n]->test($KKCIIntStr, @KKCIMarkovTest);
    warn "\n";
}

foreach $n (@Kcross){                             # コーパスをメモリに読み込む
    $FILE = sprintf($CTEMPL, $n);
    open(FILE) || die "Can't open $FILE: $!\n";
    warn "Reading $FILE in Memory\n";
    while (<FILE>){
        ($.%$STEP == 0) || next;
        foreach $unit (&Line2Units($_)){             # [表記/読み] 単位のループ
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

@Lnew = ((1/2) x 2);                              # EMアルゴリズムの初期値
do {                                              # EMアルゴリズムのループ
    @LforKKCI = @Lnew;                            # 少々トリッキー
    @Lnew = (0) x @LforKKCI;
    foreach $n (@Kcross){                         # k-fold cross validation
        print STDERR $n, " ";
        @Ltmp = $KKCIMarkov[$n]->OneIteration($Tran[$n], @LforKKCI);
        grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforKKCI));
    }
    @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforKKCI));
    printf(STDERR "λ = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
} while (! &eq($TEMPLATE, \@Lnew, \@LforKKCI));

undef(@KKCIMarkov);

$FILE = "> $LAMBDA";                              # 補間係数ファイルの生成
open(FILE) || die "Can't open $FILE: $!\n";
print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforKKCI)), "\n";
close(FILE);

LforWNoEst:

open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
@LforKKCI = map($_+0.0, split(/[ ,]+/, <LAMBDA>));
close(LAMBDA);


#-------------------------------------------------------------------------------------
#                        $KKCIMarkov の生成
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
#                        エントロピーの計算
#-------------------------------------------------------------------------------------

$CORPUS = sprintf($CTEMPL, 10);                   # テストコーパス
open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";
for ($logP = 0, $Tnum = 0; <CORPUS>; ){
    foreach $unit (&Line2Units($_)){             # [表記/読み] 単位のループ
        ($word, $kkci) = split("/", $unit);
        next unless ($WordIntStr->int($word) == $WordIntStr->int($UT));
        @char = ($kkci =~ m/(..)/g);
        my(@stat) = ($BT) x 1;
        foreach $char (@char, $BT){
            $Tnum++;
            push(@stat, $KKCIIntStr->int($char));
#            printf("F(%s) = %d\n", $char, $KKCIMarkov->_1gram($stat[1]));
            if ($stat[1] != $KKCIIntStr->int($UT)){ # 既知読みの場合
#                printf(STDERR "%s\n", $char);
                $logP += $KKCIMarkov->logP(@stat, @LforKKCI);
            }else{                                   # 未知読みの場合
#                printf(STDERR "UT %s\n", $char);
                $logP += $KKCIMarkov->logP(@stat, @LforKKCI);
                $logP += -log(1/$KKCIUT);
            }
            shift(@stat);
        }
    }
}
close(CORPUS);

printf(STDERR "文字数 = %d, H = %8.6f\n", $Tnum, $logP/$Tnum/log(2));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

warn "Done\n";
exit(0);


#-------------------------------------------------------------------------------------
#                        KKCIIntStr
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、文字と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

sub KKCIIntStr{
    warn "main::KKCIIntStr\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_), $BT){ # [表記/読み] 単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、形態素レベルのマルコフモデルを生成する

sub KKCIMarkov{
    warn "main::KKCIMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){     # [表記/読み] 単位のループ
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

    $markov->inc(($KKCIIntStr->int($UT)) x ($MO+1)); # F(UT) > 0 を保証する (floaring)
}


#=====================================================================================
#                        END
#=====================================================================================
