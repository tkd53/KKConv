#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       MakeInDictDA.perl
#                             bShinsuke Mori
#                             Last change 1 April 2009
#=====================================================================================

# 機  能 : WordIntStr.text と WordMarkov.db から以下のファイルを生成する。
#
#            1) InDict.datran : オートマトンの遷移表
#                 ((P_ACData)(P_ATranT)^0x59)+
#            2) InDict.dadata : 長さと品詞番号と頻度の組の列
#                 (Length・Part・Freq)+
#
# 使用法 : MakeInDictDA.perl
#
# 実  例 : MakeInDictDA.perl
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$TKD53HOME/lib/perl");

#require "Help.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 0) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";


#-------------------------------------------------------------------------------------
#                        共通の変数や関数の定義を読み込む
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWordYomi.perl";


#-------------------------------------------------------------------------------------
#                        $WordIntStr と $WordMarkov の生成
#-------------------------------------------------------------------------------------

$WordIntStr = new IntStr("WordIntStr.text");
$WordMarkov = new MarkovHashDisk($WordIntStr->size, "WordMarkov");


#-------------------------------------------------------------------------------------
#                        %MotPos の生成
#-------------------------------------------------------------------------------------

%MotPos = ();                                     # 表記 -> (品詞番号, 出現頻度)+
foreach $part (2 .. $WordIntStr->size-1){
    $unit = $WordIntStr->str($part);
    $word = (split("/", $unit))[0];
    $freq = $WordMarkov->_1gram($part);
    $MotPos{$word} .= pack("II", $part, $freq);
#    printf(STDERR "F(%s) = %d\n", $word, $freq);
}


#-------------------------------------------------------------------------------------
#                        $DATran の生成
#-------------------------------------------------------------------------------------

warn "\$DATran の生成\n";

# ノードの ID は $DATran の先頭からのバイト数
# $DATran の各状態の先頭の１バイトは形態素列へのポインター
$DATran = pack("I", 0) x 0x60;                    # トライの遷移表(初期値はルート)
for ($char = 1; $char < 0x60; $char++){           # ルートノードの初期化
    $nextnode = length($DATran);
    substr($DATran, $char*4, 4) = pack("I", $nextnode);
    $DATran .= pack("I", 0) x 0x60;               # ルートの直下のノードの初期化
}

foreach $word (keys(%MotPos)){                    # 全ての異なり表記に対するループ
    @char = map(ord($_)^0xff, split("", $word));# 遷移表の添字に分解
#    printf(STDERR "%s =" . " %02x" x @char . "\n", $word, @char);
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
$SENTINEL = pack("III", 0, 0, 0);                 # 出力表の番兵
$OutPut = $SENTINEL;                              # (Length・Part・Freq)+
$contex = "";                                     # trieの文脈 = MotPosのキー
&search($currnode = 0);                           # trieの深さ優先探索

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

warn "辞書検索の実験\n";

select(STDERR);
$_ = "今日は良い天気だ";
print $_, "\n";
for ($node = 0, $suf = 0; $suf < length; $suf += 2){
    $char = ord(substr($_, $suf+0, 1))^0xff;
    $node = unpack("I", substr($DATran, $node+$char*4, 4));
    $char = ord(substr($_, $suf+1, 1))^0xff;
    $node = unpack("I", substr($DATran, $node+$char*4, 4));

    $outpos = unpack("I", substr($DATran, $node, 4));

    for ($off = 0; ; $off += 12){
        ($len, $pos, $fre) = unpack("III", substr($OutPut, $outpos+$off, 12));
        ($len > 0) || last;
        printf("%s%s(%4d)\n", " " x (2+$suf-$len*2), $WordIntStr->str($pos), $fre);
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

# Global Variables : %MotPos, $contex, %IntStr, $DATran, $TTranT, $SENTINEL
sub search{
    my($currnode) = @_;
    my($char, $nextnode, $string);
    my($data, $off, $len, $pos, $fre, $i, $temp);

    if (length($contex)%2 == 0){
        for ($data = "", $len = length($contex); $len > 0; $len -= 2){
            $dict = $MotPos{substr($contex, -$len, $len)};
            for ($i = 0; $i < length($dict); $i += 8){
                $data .= pack("I", int($len/2)) . substr($dict, $i, 8);
            }
        }
        if ($data ne ""){                         # この位置で終る形態素がある場合
            substr($DATran, $currnode, 4) = pack("I", length($OutPut));
            $OutPut .= $data . $SENTINEL;
        }
    }

    for ($char = 0x01; $char < 0x60; $char++){
        $nextnode = unpack("I", substr($TTranT, $currnode+$char*4, 4));
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
    return (0);
}


#=====================================================================================
#                        END
#=====================================================================================
