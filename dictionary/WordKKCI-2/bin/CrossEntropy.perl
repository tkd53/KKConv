#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       CrossEntropy.perl
#                             bShinsuke Mori
#                             Last change 13 March 2016
#=====================================================================================

# 機  能 : 単語と読みの組の 2-gram を用いて Cross Entropy を計算する。
#
# 使用法 : CrossEntropy.perl STEP [TEST]
#
# 実  例 : CrossEntropy.perl 0 ../../corpus/10.wordkkci
#
# 注意点 : (filestem).wordkkci は "表記/読み ..." となっていなければならない。
#          行数が 4**ARGV[0] で割り切れる文だけを用いて学習する。


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use English;
use File::Basename;
unshift(@INC, "$TKD53HOME/lib/perl");

require "Help.pm";                                # In $HOME/usr/lib/perl
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

(((@ARGV == 1) || (@ARGV == 2)) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";
print STDERR join(":", $HOST, $PID), "\n";

$STEP = 4**shift;                                 # 学習コーパスの文のステップ
$TEST = (@ARGV) ? shift : undef;


#-------------------------------------------------------------------------------------
#                        共通の変数や関数の定義を読み込む
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # 真
use constant FAUX => 0;                           # 偽

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWordKKCI.perl";


#-------------------------------------------------------------------------------------
#                        固有の変数の定義
#-------------------------------------------------------------------------------------

$MO = 1;                                          # マルコフモデルの次数

@WordMarkovTest = (&Line2Units($WordMarkovTest))[0 .. $MO];
@CharMarkovTest = (split(" ", $CharMarkovTest))[0 .. $MO];


#-------------------------------------------------------------------------------------
#                        $WordIntStr の生成
#-------------------------------------------------------------------------------------
printf("Generating WordIntStr...");
(-e ($FILE = "WordIntStr.text")) ||               # ファイルがあるか？  なければ作る。
    &WordIntStr($FILE, map(sprintf($CTEMPL, $_), @Kcross));
$WordIntStr = new IntStr($FILE);

#goto CharMarkov;


#-------------------------------------------------------------------------------------
#                        単語マルコフモデルの補間係数の推定
#-------------------------------------------------------------------------------------

printf("Generating WordLambda...");
$LAMBDA = "WordLambda";                           # 補間係数のファイル
(-r $LAMBDA) || &CalcWordLambda($MO, $LAMBDA);    # ファイルがなければ計算

@LforWord = &ReadLambda($LAMBDA);


#-------------------------------------------------------------------------------------
#                        $WordMarkov の生成
#-------------------------------------------------------------------------------------

printf("Generating WordMarkov...");
if (-e (($FILE = "WordMarkov") . $MarkovHash::SUFFIX)){
#    $WordMarkov = new MarkovHashMemo($WordIntStr->size, $FILE);
    $WordMarkov = new MarkovHashDisk($WordIntStr->size, $FILE);
}else{
    $WordMarkov = new MarkovHashMemo($WordIntStr->size);
    &WordMarkov($WordMarkov, map(sprintf($CTEMPL, $_), @Kcross));
#    $DIRE = "/dev/shm";                           # 時間がかかるので一旦 RAM DISK に
#    $WordMarkov->put("$DIRE/$FILE");
#    system("/bin/mv $DIRE/$FILE.db .");
    $WordMarkov->put($FILE);
}
$WordMarkov->test($WordIntStr, @WordMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        $CharIntStr の生成
#-------------------------------------------------------------------------------------
printf("Generating CharInterStr...");
CharMarkov:

(-e ($FILE = "CharIntStr.text")) ||               # ファイルがあるか？  なければ作る。
    &CharIntStr($FILE, map(sprintf($CTEMPL, $_), @Kcross));
$CharIntStr = new IntStr($FILE);

$CharUT = $CharAlphabetSize-($CharIntStr->size-2);# 未知文字の数


#-------------------------------------------------------------------------------------
#                        文字マルコフモデルの補間係数の推定
#-------------------------------------------------------------------------------------

$LAMBDA = "CharLambda";                           # 補間係数のファイル
(-r $LAMBDA) || &CalcCharLambda(1, $LAMBDA);      # ファイルがなければ計算

@LforChar = &ReadLambda($LAMBDA);


#-------------------------------------------------------------------------------------
#                        $CharMarkov の生成
#-------------------------------------------------------------------------------------

if (-e (($FILE = "CharMarkov") . $MarkovHash::SUFFIX)){
    $CharMarkov = new MarkovHashMemo($CharIntStr->size, $FILE);
}else{
    $CharMarkov = new MarkovHashMemo($CharIntStr->size);
    &CharMarkov($CharMarkov, map(sprintf($CTEMPL, $_), @Kcross));
    $CharMarkov->put($FILE);
}
#$CharMarkov->test($CharIntStr, @CharMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        @EXDICT の生成 (既知語の除去)
#-------------------------------------------------------------------------------------

goto NoExDict;

$EXDICT = "ExDict.text";

@ExDict = ();
open(EXDICT) || die "Can't open $EXDICT: $!\n";
while (chop($word = <EXDICT>)){
    next if ($WordIntStr->int($word) ne $WordIntStr->int($UT));
    push(@ExDict, $word);                         # 外部辞書語リストに追加
}
close(EXDICT);


#----------------------- 既知語の累積確率の計算 --------------------------------------

$prob = 0;                                        # 内部辞書語の累積生成確率
foreach $word ($WordIntStr->strs){
    $prob += exp(-&UWlogP($word));                # 内部辞書語の生成確率の加算
#    printf("STDERR %s %6.4f\n", $word, &UWlogP($word));  # for debug
}


#----------------------- %ExDict の生成 ----------------------------------------------

%ExDict;

$prob /= scalar(@ExDict);                         # 外部辞書語へ等分するときの確率値
#printf("STDERR prob = %20.18f\n", $prob);                # for debug
foreach $word (@ExDict){
    $logP = -log(exp(-&UWlogP($word))+$prob);     # 生成確率
#    printf(STDERR "%20s %6.3f\n", $word, $logP);  # for debug
    $EXDICT{$word} = $logP;
}

NoExDict:


#-------------------------------------------------------------------------------------
#                        エントロピーの計算
#-------------------------------------------------------------------------------------

$FLAG = VRAI;                                     # 文毎のログの表示
$FLAG = FAUX;

$CORPUS = $TEST ? $TEST : sprintf($CTEMPL, 10);   # テストコーパス

open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";
$logP = $UMlogP = 0, $Cnum = $Wnum = 0;
while (<CORPUS>){
    $cnum = scalar(&Line2Chars($_))+1;            # 予測対象の文字数(文末記号を含む)
    $wnum = scalar(&Line2Units($_))+1;            # 予測対象の単語数(文末記号を含む)

    $logp = $UMlogp = 0;
    my(@stat) = ($WordIntStr->int($BT)) x $MO;
    foreach $unit (&Line2Units($_), $BT){         # 単語単位のループ
        push(@stat, $WordIntStr->int($unit));
#        printf(STDERR "f(%s) = %d\n", $unit, $WordMarkov->_1gram($unit));
        $logp += -log($WordMarkov->prob(@stat, @LforWord));
        if ($stat[$MO] == $WordIntStr->int($UT)){ # 未知語の場合
            $word = (split("/", $unit))[0];       # 表記のみ予測
#            $UMlogp += defined($EXDICT{$word}) ? $EXDICT{$word} : &UWlogP($word);
            $UMlogp += &UWlogP($word);
        }
        shift(@stat);
    }

    $FLAG && printf(STDERR "%s", $_);
    $FLAG && printf(STDERR "  文字数 = %d, H = %8.6f\n", $cnum, $logp/$cnum/log(2));
    $FLAG && printf(STDERR "  単語数 = %d, PP = %8.6f\n\n", $wnum, exp($logp/$wnum));

    $Cnum += $cnum;
    $Wnum += $wnum;
    $logP += $logp;
    $UMlogP += $UMlogp;
}
close(CORPUS);

printf(STDERR "語彙サイズ = %d\n", $WordIntStr->size());
printf(STDERR "非零2-gram = %d\n", $WordMarkov->nonzero());
printf(STDERR "文字数 = %d, H = %8.6f ", $Cnum, $logP/$Cnum/log(2));
printf(STDERR "+ %8.6f(未知語の表記予測)\n", $UMlogP/$Cnum/log(2));
#printf(STDERR "単語数 = %d, PP = %8.6f\n", $Wnum, exp($logP/$Wnum));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#=====================================================================================
#                        END
#=====================================================================================
