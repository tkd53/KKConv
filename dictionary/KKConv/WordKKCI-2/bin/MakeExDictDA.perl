#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       MakeExDictDA.perl
#                             bShinsuke Mori
#                             Last change 10 September 2011
#=====================================================================================

# 機  能 : 仮名漢字変換用の外部辞書を構成する。頻度もカウントされる。
#
# 使用法 : MakeExDictAC.perl (FILENAME) ...
#
# 実  例 : MakeExDictAC.perl ExDict.wordkkci
#
# 注意点 : (filestem) は "表記/入力\n" となっていなければならない。
#                        f(y,w)
#          確率値は -log ------ P(w|UT) として記憶する。
#                         f(w)

#          既知語の累積確率の分配をしていない


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use English;
use File::Basename;
unshift(@INC, dirname($0), "$TKD53HOME/lib/perl");

require "Help.pm";
require "Char.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV > 0) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";


#-------------------------------------------------------------------------------------
#                        共通の変数や関数の定義を読み込む
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWordKKCI.perl";
do "dofile/KKConvSetVariables.perl";

$MO = 1;                                          # マルコフモデルの次数
@CharMarkovTest = (split(" ", $CharMarkovTest))[0 .. $MO];
#print join(" ", @CharMarkovTest), "\n";


#-------------------------------------------------------------------------------------
#                        未知語モデルの読み込み
#-------------------------------------------------------------------------------------

$CharAlphabetSize = scalar(@KKCInput);            # 上書き(入力記号のアルファベット数)
($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("KKCI");
#($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);
$CharMarkov->test($CharIntStr, @CharMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        $WordIntStr の生成
#-------------------------------------------------------------------------------------

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        ExDict.text の生成 (既知語の除去)
#-------------------------------------------------------------------------------------

$FILE = "ExDict.text";
warn "$FILE の生成 (既知語の除去)\n";

%PairFreq = ();
%WordFreq = ();
while (chop($pair = <>)){
    next if ($WordIntStr->int($pair) != $WordIntStr->int($UT));
    ($word, $kkci) = split("/", $pair, 2);
    ($kkci =~ m/^($KKCInput)+$/) || ((warn $kkci, "\n") && (next));
    (grep($_ eq "　", ($word =~ m/(..)/g))) && ((warn $word, "\n") && (next));
    (length($kkci) > 16*2) && ((warn $word, "\n") && (next));
    $PairFreq{$pair}++;
    $WordFreq{$word}++;
}

print STDERR "#accepted pairs: ", scalar(keys(%PairFreq)), "\n";
(%PairFreq > 0) || die;
#foreach $word (keys(%PairFreq)){
#    printf(STDERR "  %s\n", $word);
#}

open(FILE, "> $FILE") || die "Can't open $EXDICT: $!\n";
print FILE join("\n", $UT, sort(keys(%WordFreq))), "\n";
close(FILE);

$ExText = new IntStr($FILE);


#-------------------------------------------------------------------------------------
#                        %KKCIData の生成
#-------------------------------------------------------------------------------------

%KKCIData = ();                                   # 入力 -> (表記番号, 負対数確率)+
while (($pair, $freq) = each(%PairFreq)){
    ($word, $kkci) = split("/", $pair);           # (表記, 入力)
    $text = $ExText->int($word);                  # 表記番号
#    $logP = -log($PairFreq{$pair}/$WordFreq{$word})+&UWlogP($word);
    $logP = -log($PairFreq{$pair}/$WordFreq{$word})+&UWlogP($kkci);
    $KKCIData{$kkci} .= pack("Id", $text, $logP);
#    printf(STDERR "%s -> %s, %10.6f\n", $kkci, $ExText->str($text), $logP);
}


#-------------------------------------------------------------------------------------
#                        $DATran の生成
#-------------------------------------------------------------------------------------

# ノードの ID は $DATran の先頭からのバイト数
# $DATran の各状態の先頭の１バイトは形態素列へのポインター
$DATran = pack("I", 0) x 0x60;                    # トライの遷移表(初期値はルート)
for ($char = 1; $char < 0x60; $char++){           # ルートノードの初期化
    $nextnode = length($DATran);
    substr($DATran, $char*4, 4) = pack("I", $nextnode);
    $DATran .= pack("I", 0) x 0x60;               # ルートの直下のノードの初期化
}

foreach $kkci (keys(%KKCIData)){                  # 全ての異なり表記に対するループ
    @char = map(ord($_)^0xff, split("", $kkci));  # 遷移表の添字に分解
#    printf(STDERR "%s =" . " %02x" x @char . "\n", $kkci, @char);
    for ($currnode = 0; $char = shift(@char); $currnode = $nextnode){
        $nextnode = unpack("I", substr($DATran, $currnode+$char*4, 4));
        if ($nextnode == 0){                      # 次の状態が未登録の場合
            $nextnode = length($DATran);
            substr($DATran, $currnode+$char*4, 4) = pack("I", $nextnode);
            $DATran .= pack("I", 0) x 0x60;
        }
#        printf(STDERR "  char = 0x%02x, folpos = 0x%06x\n", $char, $nextnode);
    }
}

printf(STDERR "%d[KB]\n", length($DATran)/1024);

$TTranT = $DATran;
$SENTINEL = pack("IId", 0, 0, 0.0);               # 出力表の番兵
$OutPut = $SENTINEL;                              # (Length・Text・LogP)+
$contex = "";                                     # trie の文脈 = KKCIData のキー
&search($currnode = 0);                           # trie の深さ優先探索

$DATRAN = "> ExDict.datran";
open(DATRAN) || die "Can't open $DATRAN: $!\n";
print DATRAN $DATran;
close(DATRAN);

$DADATA = "> ExDict.dadata";
open(DADATA) || die "Can't open $DADATA: $!\n";
print DADATA $OutPut;
close(DADATA);


#-------------------------------------------------------------------------------------
#                        辞書検索の実験
#-------------------------------------------------------------------------------------

select(STDERR);
$_ = "１しゅうかんごとにはやばんと";
print $_, "\n";
for ($node = 0, $suff = 0; $suff < length; $suff += 2){
    $char = ord(substr($_, $suff+0, 1))^0xff;
    $node = unpack("I", substr($DATran, $node+$char*4, 4));
    $char = ord(substr($_, $suff+1, 1))^0xff;
    $node = unpack("I", substr($DATran, $node+$char*4, 4));

    $outpos = unpack("I", substr($DATran, $node, 4));

    for ($offset = 0; ; $offset += 16){
        ($length, $text, $logP) = unpack("IId", substr($OutPut, $outpos+$offset, 16));
        ($length > 0) || last;
        printf("%s%s/%s(%10.8f)\n", " " x (2+$suff-$length*2),
               substr($_, 2+$suff-$length*2, $length*2), $ExText->str($text),
               $logP);
    }
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

warn "Done\n";
exit(0);


#-------------------------------------------------------------------------------------
#                        sub search
#-------------------------------------------------------------------------------------

# Global Variables : %KKCIData, $contex, $DATran, $TTranT, $SENTINEL
sub search{
    my($currnode) = @_;
    my($char, $nextnode, $string);
    my($data, $off, $len, $pos, $fre, $i, $temp);

    if (length($contex)%2 == 0){
        for ($data = "", $len = length($contex); $len > 0; $len -= 2){
            $dict = $KKCIData{substr($contex, -$len, $len)};
            for ($i = 0; $i < length($dict); $i += 12){
                $data .= pack("I", int($len/2)) . substr($dict, $i, 12);
            }
        }
        if ($data ne ""){                         # この位置で終る形態素がある場合
            substr($DATran, $currnode, 4) = pack("I", length($OutPut));
            $OutPut .= $data . $SENTINEL;
        }
    }

    for ($char = 0x01; $char < 0x60; $char++){
        $nextnode = unpack("I", substr($TTranT, $currnode+$char*4, 4)); # on memory
        if ($nextnode == 0){                      # 遷移先がない場合
            $string = $contex . chr($char^0xff);  # 次の文字をつけてみる
            $nextnode = &findLS($string);         # 最長の接尾辞を求める
            substr($DATran, $currnode+$char*4, 4) = pack("I", $nextnode);
            next;
        }
        $contex .= chr($char^0xff);
        &search($nextnode);
        chop($contex);
    }
}


#-------------------------------------------------------------------------------------
#                        sub findLS
#-------------------------------------------------------------------------------------

# trie のノードに対応する最長の接尾辞を見つけ、そのノード番号を返す。
sub findLS{
    my($string) = @_;
    my($pos, $off, $node);

    for ($pos = 2; $pos < length($string); $pos += 2){
        # $pos から始まる部分文字列による trie の探索
        for ($node = 0, $off = 0; $pos+$off < length($string); $off++){
            $char = ord(substr($string, $pos+$off, 1))^0xff;
            $node = unpack("I", substr($TTranT, $node+$char*4, 4));
            last if ($node == 0);
        }
        ($node != 0) && return ($node);
    }
    return(0);
}


#=====================================================================================
#                        END
#=====================================================================================
