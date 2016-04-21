#!/usr/bin/env perl
#=====================================================================================
#                       MakeExDictDA.perl
#                             bShinsuke Mori
#                             Last change 10 September 2011
#=====================================================================================

# ��  ǽ : ̤�θ��ǥ�ˤ����θ��������Ψ�ι���ͤ�׻�������������θ��Ф������
#          ʬ���롣�ʲ��Υե�������������롣
#
#            1) ExDict.datran : �����ȥޥȥ������ɽ
#                 ((P_ACData)(P_ATranT)^0x59)+
#            2) ExDict.dadata : Ĺ�����ʻ��ֹ�����п���Ψ�ͤ��Ȥ���
#                 (Length��LogP)+
#
# ����ˡ : MakeExDictDA.perl (filename)
#
# ��  �� : MakeExDictDA.perl ExDict.text
#
# ����� : (filestem) �γƹԤ� "ɽ��/�ʻ�\n" �ȤʤäƤ��ʤ���Фʤ�ʤ���


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
unshift(@INC, dirname($0), "$TK53HOME/lib/perl");

require "Help.pm";
require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";
require "class/MarkovHashDisk.pm";
require "class/MarkovDiadMemo.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 1) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";

$EXDICT = shift;                                  # ��������ե�����


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ���ؿ���������ɤ߹���
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";
do "dofile/KKConvSetVariables.perl";


#-------------------------------------------------------------------------------------
#                        $WordIntStr �� $WordMarkov ������
#-------------------------------------------------------------------------------------

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        @EXDICT ������ (���θ�ν���)
#-------------------------------------------------------------------------------------

%ExDict = ();
open(EXDICT) || die "Can't open $EXDICT: $!\n";
while (chop($wordkkci = <EXDICT>)){
    ($word, $kkci) = split("/", $wordkkci);
    next if ($WordIntStr->int($wordkkci) ne $WordIntStr->int($UT));
    &IsEUCZenkaku($word) || die $wordkkci;
    &IsEUCZenkaku($kkci) || die $wordkkci;
    $ExDict{$word} = 1;                            # ���������ꥹ�Ȥ��ɲ�
}
close(EXDICT);
@ExDict = keys(%ExDict);

print STDERR "�������񥨥�ȥ꡼��: ", scalar(@ExDict), "\n";
(scalar(@ExDict) > 0) || die;

#printf(STDERR "%s\n", "-" x 80);
#foreach $word (@ExDict){
#    printf(STDERR "  %s\n", $word);
#}


#-------------------------------------------------------------------------------------
#                        ʸ�� 2-gram ��ǥ���ɤ߹���
#-------------------------------------------------------------------------------------

($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);

#$word = "��ø";
#printf(STDERR "%s %6.4f\n", $word, &UWlogP($word));  # for debug


#-------------------------------------------------------------------------------------
#                        %MotPos ������
#-------------------------------------------------------------------------------------

warn "���θ�����ѳ�Ψ�η׻�\n";

$prob = 0;                                        # ��������������������Ψ
foreach $wordkkci ($WordIntStr->strs){
#    printf(STDERR "%-21s ", $wordkkci);
    ($wordkkci ne $UT) || next;
    ($wordkkci ne $BT) || next;
    ($word, $kkci) = split("/", $wordkkci);
    $prob += exp(-&UWlogP($word));                # ����������������Ψ�βû�
#    printf(STDERR "%s %6.4f\n", $word, &UWlogP($word));  # for debug
}

%MotPos = ();                                     # ɽ�� -> (�ʻ��ֹ�, ������Ψ)+
$prob /= scalar(@ExDict);                         # ������������ʬ����Ȥ��γ�Ψ��
#    printf(STDERR "prob[%s] = %20.18f\n", $prob); # for debug
foreach $word (@ExDict){
    $logP = -log(exp(-&UWlogP($word))+$prob);     # ������Ψ
#        printf(STDERR "%20s %6.3f\n", $word, $logP); # for debug
    $MotPos{$word} .= pack("d", $logP);
}


#-------------------------------------------------------------------------------------
#                        $DATran ������
#-------------------------------------------------------------------------------------

warn "\$DATran ������\n";

# �Ρ��ɤ� ID �� $DATran ����Ƭ����ΥХ��ȿ�
# $DATran �γƾ��֤���Ƭ�Σ��Х��ȤϷ�������ؤΥݥ��󥿡�
$DATran = pack("I", 0) x 0x60;                    # �ȥ饤������ɽ(����ͤϥ롼��)
for ($char = 1; $char < 0x60; $char++){           # �롼�ȥΡ��ɤν����
    $nextnode = length($DATran);
    substr($DATran, $char*4, 4) = pack("I", $nextnode);
    $DATran .= pack("I", 0) x 0x60;               # �롼�Ȥ�ľ���ΥΡ��ɤν����
}

foreach $word (keys(%MotPos)){                    # ���Ƥΰۤʤ�ɽ�����Ф���롼��
    @char = map(ord($_)^0xff, split("", $word));  # ����ɽ��ź����ʬ��
#    printf(STDERR "%s =" . " %02x" x @char . "\n", $word, @char);
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
$SENTINEL = pack("Id", 0, 0.0);                   # ����ɽ����ʼ
$OutPut = $SENTINEL;                              # (Length��logP)+
$contex = "";                                     # trie��ʸ̮ = MotPos�Υ���
&search($currnode = 0);                           # trie�ο���ͥ��õ��

$DATRAN = "> ExDict.datran";
open(DATRAN) || die "Can't open $DATRAN: $!\n";
print DATRAN $DATran;
close(DATRAN);

$DADATA = "> ExDict.dadata";
open(DADATA) || die "Can't open $DADATA: $!\n";
print DADATA $OutPut;
close(DADATA);


#-------------------------------------------------------------------------------------
#                        ���񸡺��μ¸�
#-------------------------------------------------------------------------------------

select(STDERR);
$_ = "�������ɤ�ŷ����";
print $_, "\n";
for ($node = 0, $suf = 0; $suf < length; $suf += 2){
    $char = ord(substr($_, $suf+0, 1))^0xff;
    $node = unpack("I", substr($DATran, $node+$char*4, 4));
    $char = ord(substr($_, $suf+1, 1))^0xff;
    $node = unpack("I", substr($DATran, $node+$char*4, 4));

    $outpos = unpack("I", substr($DATran, $node, 4));

    for ($off = 0; ; $off += 12){
        ($len, $log) = unpack("Id", substr($OutPut, $outpos+$off, 12));
        ($len > 0) || last;
        printf("%s%s(%6.3f)\n", " " x (2+$suf-$len*2),
               substr($_, 2+$suf-$len*2, $len*2), $log);
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
                $data .= pack("I", int($len/2)) . substr($dict, $i, 12);
            }
        }
        if ($data ne ""){                         # ���ΰ��֤ǽ�������Ǥ�������
            substr($DATran, $currnode, 4) = pack("I", length($OutPut));
            $OutPut .= $data . $SENTINEL;
        }
    }

    for ($char = 0x01; $char < 0x60; $char++){
        $nextnode = unpack("I", substr($TTranT, $currnode+$char*4, 4));
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
    return (0);
}


#-------------------------------------------------------------------------------------
#                        sub IsEUCZenkaku
#-------------------------------------------------------------------------------------

# ��  ǽ : EUC ������ʸ����Ǥ뤫

sub IsEUCZenkaku{
    (@_ == 1) || die;
    my($string) = @_;
    my(@code) = split("", $string);

    (scalar(@code)%2 == 0) || return(0);
    (grep(ord($_) < 0x80, @code)) && return(0);

    return(1);
}


#=====================================================================================
#                        END
#=====================================================================================
