#!/usr/bin/env perl
#=====================================================================================
#                       WordYomiProb.perl
#                             bShinsuke Mori
#                             Last change 16 May 2009
#=====================================================================================

# 機  能 : 入力記号列に対する可能な表記と確率を算出する
#
# 使用法 : WordYomiProb.perl (STEM)
#
# 実  例 : WordYomiProb.perl ~/SLM/text/MMH/MMH-L < yomi/02-gram
#
# 注意点 : 標準入力をまつ
#          確率の降順に出力する
#          出力部分は sub search の中にある


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
require "Char.pm";

require "SArray.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";


#-------------------------------------------------------------------------------------
#                        共通の変数や関数の定義を読み込む
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # 真
use constant FAUX => 0;                           # 偽

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 1) && ($ARGV[0] ne "-help")) || &Help($0);

$STEM = shift;

$PATH = dirname($STEM);
$STEM = basename($STEM);


#-------------------------------------------------------------------------------------
#                        固有の変数の定義
#-------------------------------------------------------------------------------------

@WordMarkovTest = (&Morphs2Words($MorpMarkovTest))[0 .. 1];


#-------------------------------------------------------------------------------------
#                        $text を設定
#-------------------------------------------------------------------------------------

$text = new SArray(join("/", $PATH, $STEM));

$text->test(qw( 抗 ヒスタミン ));                 # $text のテスト


#-------------------------------------------------------------------------------------
#                        単漢字辞書
#-------------------------------------------------------------------------------------

# text に出てこない文字は不要

$TANKAN = "link/resource/dict/tankan";
@FILE = qw( JIS1.text JIS2.text Kana.text Kigo.text Suji.text );
%TANKAN = ();                                     # 読み => (文字)+
#$CharYomi = 1;                                    # BT の分
foreach $FILE (@FILE){
    $FILE = join("/", $HOME, $TANKAN, $FILE);
    open(FILE) || die "Can't open $FILE: $!\n";
    while (chop($_ = <FILE>)){                    # main loop
        (m/^\#/) && next;                         # コメント行
        (m/^\s*$/) && next;                       # 空行
        ($char, @yomi) = split;
        ($text->Freq($char) > 0) || next;         # 生コーパスに出現しない文字の場合
        foreach $yomi (@yomi){
            if (defined($TANKAN{$yomi})){
                push(@{$TANKAN{$yomi}}, $char);
            }else{
                $TANKAN{$yomi} = [$char];
            }
        }

#        $CharYomi += @yomi;
    }
    close(FILE);
}

#$yomi = "アイ";
#printf("%s => %s\n", $yomi, join(" ", @{$TANKAN{$yomi}}));
#exit(0);


#-------------------------------------------------------------------------------------
#                        未知語読みモデル
#-------------------------------------------------------------------------------------

#$YOMIROOT = "$HOME/SLM/EDR/Yomi/Morp-2/Step0";
#
#$FILE = "$YOMIROOT/TankanIntStr.text";
#$TankanIntStr = new IntStr($FILE);
#$CharYomi -= ($TankanIntStr->size()-1);
#
#$LAMBDA = "$YOMIROOT/TankanLambda";
#open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
#@LforTankan = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
#close(LAMBDA);
#
#$FILE = "$YOMIROOT/TankanMarkov";
#$TankanMarkov = new MarkovHashMemo($TankanIntStr->size, $FILE);


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

while (chop($yomi = <>)){
    @line = ();
    &search($yomi, "", ());                       # 再帰的に探索(本来はDPであるべきか)
#    print STDERR $yomi, "\n";
    foreach (@line){
        ($logP, $word, @elem) = split;
        printf("%10.5f %s %s\n", $logP, $word, join(" ", @elem));
    }
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

print STDERR "Done\n";
exit(0);


#-------------------------------------------------------------------------------------
#                        calc
#-------------------------------------------------------------------------------------

# 機  能 : 表記への分割の再帰的探索
#
# 注意点 : グローバル変数 @line を書き換える

sub search{
    (@_ > 1) || die;
    my($yomi) = shift;
    my($word) = shift;
    my(@pair) = @_;

    my($length) = length($yomi)/2;

    my($i);
    for ($i = 1; $i < $length; $i++){
        my($head) = substr($yomi, 0, 2*$i);
        foreach $char (@{$TANKAN{$head}}){
            my($temp) = $word . $char;
            ($text->Freq($temp) > 0) || next;     # 生コーパスに出現しない単語の場合
            &search(substr($yomi, 2*$i), $temp, (@pair, join("/", $char, $head)));
        }
    }
#    ($i == $length) || die;

    my($head) = substr($yomi, 0, 2*$i);
    foreach $char (@{$TANKAN{$head}}){
        my(@elem) = (@pair, join("/", $char, $head));
        my($temp) = $word . $char;
        ($text->Freq($temp) > 0) || next;         # 生コーパスに出現しない単語の場合
        print join(" ", @elem), "\n";             # 出力
#        push(@line, sprintf("%10.5f %s %s", &ent(@elem), $temp, join(" ", @elem)));
    }
# $text->freq(...) > 0
# 出力は ( 表記/読み, logP ) か for RCDict
    return;
}


#-------------------------------------------------------------------------------------
#                        ent
#-------------------------------------------------------------------------------------

# 機  能 : エントロピーの計算
#
# 注意点 : なし

sub ent{
    (@_ > 0) || die;
    my(@elem) = @_;

    my($logP) = 0;
    my($Tnum) = scalar(@elem)+1;

    my(@state) = ($TankanIntStr->int($BT)) x 1;
    foreach $char (@elem, $BT){                   # 文字単位のループ
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
