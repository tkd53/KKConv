#!/usr/bin/env perl
#=====================================================================================
#                       MakeInDictDA.perl
#                           by Shinsuke Mori
#                           Last change : 17 September 2012
#=====================================================================================

# ��  ǽ : WordIntStr.text ����ʲ��Υե�������������롣
#
#            1) InDict.datran : �����ȥޥȥ������ɽ
#                 ((P_ACData)(P_ATranT)^0x59)+
#            2) InDict.dadata : Ĺ���Ⱦ����ֹ�ȳ�Ψ���Ȥ���
#                 (Length��Stat��LogP)+
#
# ����ˡ : MakeInDictDA.perl (STEP)
#
# ��  �� : MakeInDictDA.perl 4
#
# ����� : log P(y|<w,y>) = 0 ��ǡ���������Ƥ���


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

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        %KKCIData ������
#-------------------------------------------------------------------------------------

%KKCIData = ();                                   # �ɤ� -> (�����ֹ�, ���п���Ψ)+
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
#                        $DATran ������
#-------------------------------------------------------------------------------------

# �Ρ��ɤ� ID �� $DATran ����Ƭ����ΥХ��ȿ�
# $DATran �γƾ��֤���Ƭ�Σ��Х��ȤϷ�������ؤΥݥ��󥿡�
$DATran = pack("I", 0) x 0x60;                    # �ȥ饤������ɽ(����ͤϥ롼��)
for ($char = 1; $char < 0x60; $char++){           # �롼�ȥΡ��ɤν����
    $nextnode = length($DATran);
    substr($DATran, $char*4, 4) = pack("I", $nextnode);
    $DATran .= pack("I", 0) x 0x60;               # �롼�Ȥ�ľ���ΥΡ��ɤν����
}

foreach $kkci (keys(%KKCIData)){                  # ���Ƥΰۤʤ�ɽ�����Ф���롼��
    @char = map(ord($_)^0xff, split("", $kkci));  # ����ɽ��ź����ʬ��
#    printf(STDERR "%s =" . " %02x" x @char . "\n", $kkci, @char);
    for ($currnode = 0; $char = shift(@char); $currnode = $nextnode){
        $nextnode = unpack("I", substr($DATran, $currnode+$char*4, 4));
        if ($nextnode == 0){                      # ���ξ��֤�̤��Ͽ�ξ��
            $nextnode = length($DATran);
            substr($DATran, $currnode+$char*4, 4) = pack("I", $nextnode);
            $DATran .= pack("I", 0) x 0x60;
        }
#        printf(STDERR "  char = 0x%02x, folpos = 0x%06x\n", $char, $nextnode);
    }
}

printf(STDERR "%d[KB]\n", length($DATran)/1024);

$TTranT = $DATran;
$SENTINEL = pack("IId", 0, 0, 0.0);               # ����ɽ����ʼ
$OutPut = $SENTINEL;                              # (Length��Stat��LogP)+
$contex = "";                                     # trie ��ʸ̮ = KKCIData �Υ���
&search($currnode = 0);                           # trie �ο���ͥ��õ��

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

select(STDERR);
$_ = "�����夦���󤴤ȤˤϤ�Ф��";
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
        if ($data ne ""){                         # ���ΰ��֤ǽ�������Ǥ�������
            substr($DATran, $currnode, 4) = pack("I", length($OutPut));
            $OutPut .= $data . $SENTINEL;
        }
    }

    for ($char = 0x01; $char < 0x60; $char++){
        $nextnode = unpack("I", substr($TTranT, $currnode+$char*4, 4)); # on memory
        if ($nextnode == 0){                      # �����褬�ʤ����
            $string = $contex . chr($char^0xff);  # ����ʸ����Ĥ��Ƥߤ�
            $nextnode = &findLS($string);         # ��Ĺ�������������
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

# trie �ΥΡ��ɤ��б������Ĺ���������򸫤Ĥ������ΥΡ����ֹ���֤���
sub findLS{
    my($string) = @_;
    my($pos, $off, $node);

    for ($pos = 2; $pos < length($string); $pos += 2){
        # $pos ����Ϥޤ���ʬʸ����ˤ�� trie ��õ��
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
