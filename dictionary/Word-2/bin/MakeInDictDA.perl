#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       MakeInDictDA.perl
#                             bShinsuke Mori
#                             Last change 24 June 2014
#=====================================================================================

# ��  ǽ : WordIntStr.text �� WordMarkov.db �����ʲ��Υե��������������롣
#
#            1) InDict.datran : �����ȥޥȥ�������ɽ
#                 ((P_ACData)(P_ATranT)^0x59)+
#            2) InDict.dadata : Ĺ�����ʻ��ֹ������٤��Ȥ���
#                 (Length��Part��Freq)+
#
# ����ˡ : MakeInDictDA.perl
#
# ��  �� : MakeInDictDA.perl
#
# ������ : �ʤ�


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
($HOSTNAME =~ /arcs/) && map(s|/usr/lib/|/usr/local/lib/|, @INC);
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl");

require "Help.pm";
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
#                        ���̤��ѿ����ؿ����������ɤ߹���
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        $WordIntStr �� $WordMarkov ������
#-------------------------------------------------------------------------------------

$WordIntStr = new IntStr("WordIntStr.text");
$WordMarkov = new MarkovHashDisk($WordIntStr->size, "WordMarkov");


#-------------------------------------------------------------------------------------
#                        %StatFreq ������
#-------------------------------------------------------------------------------------

%StatFreq = ();                                   # ɽ�� => (�����ֹ�, �и�����)+
foreach $stat (2 .. $WordIntStr->size-1){         # UT �� BT ������
    $word = $WordIntStr->str($stat);
    $freq = $WordMarkov->_1gram($stat);
    $StatFreq{$word} .= pack("II", $stat, $freq);
    printf(STDERR "F(%s) = %d\n", $word, $freq);
}


#-------------------------------------------------------------------------------------
#                        $DATran ������
#-------------------------------------------------------------------------------------

warn "\$DATran ������\n";

# �Ρ��ɤ� ID �� $DATran ����Ƭ�����ΥХ��ȿ�
# $DATran �γƾ��֤���Ƭ�Σ��Х��ȤϷ��������ؤΥݥ��󥿡�
$DATran = pack("I", 0) x 0x60;                    # �ȥ饤������ɽ(�����ͤϥ롼��)
for ($char = 1; $char < 0x60; $char++){           # �롼�ȥΡ��ɤν�����
    $nextnode = length($DATran);
    substr($DATran, $char*4, 4) = pack("I", $nextnode);
    $DATran .= pack("I", 0) x 0x60;               # �롼�Ȥ�ľ���ΥΡ��ɤν�����
}

foreach $word (keys(%StatFreq)){                    # ���Ƥΰۤʤ�ɽ�����Ф����롼��
    @char = map(ord($_)^0xff, split("", $word));  # ����ɽ��ź����ʬ��
#    printf(STDERR "%s =" . " %02x" x @char . "\n", $word, @char);
    for ($currnode = 0; $char = shift(@char); $currnode = $nextnode){
        $nextnode = unpack("I", substr($DATran, $currnode+$char*4, 4));
        if ($nextnode == 0){                      # ���ξ��֤�̤��Ͽ�ξ���
            $nextnode = length($DATran);
            substr($DATran, $currnode+$char*4, 4) = pack("I", $nextnode);
            $DATran .= pack("I", 0) x 0x60;
        }
#        printf(STDERR "  char = 0x%02x, folpos = 0x%06x\n", $char, $nextnode);
    }
}

printf(STDERR "%d[KB]\n", length($DATran)/1024);

$TTranT = $DATran;
$SENTINEL = pack("III", 0, 0, 0);                 # ����ɽ����ʼ
$OutPut = $SENTINEL;                              # (Length��Part��Freq)+
$contex = "";                                     # trie��ʸ̮ = StatFreq�Υ���
&search($currnode = 0);                           # trie�ο���ͥ��õ��

$DATRAN = "> InDict.datran";
open(DATRAN) || die "Can't open $DATRAN: $!\n";
print DATRAN $DATran;
close(DATRAN);

$DADATA = "> InDict.dadata";
open(DADATA) || die "Can't open $DADATA: $!\n";
print DADATA $OutPut;
close(DADATA);


#-------------------------------------------------------------------------------------
#                        ���񸡺��μ¸�
#-------------------------------------------------------------------------------------

warn "���񸡺��μ¸�\n";

select(STDERR);
$_ = "�˽����ѵ�������ˡ���ޤ��������롣";
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

# Global Variables : %StatFreq, $contex, %IntStr, $DATran, $TTranT, $SENTINEL
sub search{
    my($currnode) = @_;
    my($char, $nextnode, $string);
    my($data, $off, $len, $pos, $fre, $i, $temp);

    if (length($contex)%2 == 0){
        for ($data = "", $len = length($contex); $len > 0; $len -= 2){
            $dict = $StatFreq{substr($contex, -$len, $len)};
            for ($i = 0; $i < length($dict); $i += 8){
                $data .= pack("I", int($len/2)) . substr($dict, $i, 8);
            }
        }
        if ($data ne ""){                         # ���ΰ��֤ǽ��������Ǥ���������
            substr($DATran, $currnode, 4) = pack("I", length($OutPut));
            $OutPut .= $data . $SENTINEL;
        }
    }

    for ($char = 0x01; $char < 0x60; $char++){
        $nextnode = unpack("I", substr($TTranT, $currnode+$char*4, 4));
        if ($nextnode == 0){                      # �����褬�ʤ�����
            $string = $contex . chr($char^0xff);  # ����ʸ�����Ĥ��Ƥߤ�
            $nextnode = &findLS($string);         # ��Ĺ����������������
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

# trie �ΥΡ��ɤ��б�������Ĺ���������򸫤Ĥ������ΥΡ����ֹ����֤���
sub findLS{
    my($string) = @_;
    my($pos, $off, $node);

    for ($pos = 2; $pos < length($string); $pos += 2){
        # $pos �����Ϥޤ���ʬʸ�����ˤ��� trie ��õ��
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
