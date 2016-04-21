#!/usr/bin/env perl
#=====================================================================================
#                       MakeInDictDA.perl
#                           by Shinsuke Mori
#                           Last change : 17 September 2012
#=====================================================================================

# 機  能 : WordIntStr.text から以下のファイルを生成する。
#
#            1) InDict.datran : オートマトンの遷移表
#                 ((P_ACData)(P_ATranT)^0x59)+
#            2) InDict.dadata : 長さと状態番号と確率の組の列
#                 (Length・Stat・LogP)+
#
# 使用法 : MakeInDictDA.perl (STEP)
#
# 実  例 : MakeInDictDA.perl 4
#
# 注意点 : log P(y|<w,y>) = 0 もデータに入れている


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
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

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        %KKCIData の生成
#-------------------------------------------------------------------------------------

%KKCIData = ();                                   # 読み -> (状態番号, 負対数確率)+
for ($stat = 2; $stat < $WordIntStr->size(); $stat++){
    $kkci = (split("/", $WordIntStr->str($stat)))[1];
    if ($kkci !~ m/^($KKCInput)+$/){
        printf(STDERR "%s -> %s, %10.6f\n", $kkci, $pair);
        die;
    }
    $logP = 0;                                    # log P(y|<w,y>) = 0
    $KKCIData{$kkci} .= pack("Id", $stat, $logP);
#    printf(STDERR "%s -> %s, %10.6f\n", $kkci, $WordIntStr->str($stat), $logP);
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
$OutPut = $SENTINEL;                              # (Length・Stat・LogP)+
$contex = "";                                     # trie の文脈 = KKCIData のキー
&search($currnode = 0);                           # trie の深さ優先探索

$DATRAN = "> InDict.datran";
open(DATRAN) || die "Can't open $DATRAN: $!\n";
print DATRAN $DATran;
close(DATRAN);

$DADATA = "> InDict.dadata";
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
        ($length, $stat, $logP) = unpack("IId", substr($OutPut, $outpos+$offset, 16));
        ($length > 0) || last;
        printf("%s%s => %s(%10.8f)\n", " " x (2+$suff-$length*2),
               substr($_, 2+$suff-$length*2, $length*2), $WordIntStr->str($stat),
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

# Global Variables : %KKCIData, $contex, %IntStr, $DATran, $TTranT, $SENTINEL
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
