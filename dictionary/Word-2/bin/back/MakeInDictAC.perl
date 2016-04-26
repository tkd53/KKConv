#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                        MakeInDictAC.perl
#                             by Shinsuke MORI
#                             Last change : 26 September 2005
#=====================================================================================

# ��  ǽ : MorpIntStr.text �� MorpMarkov.db �����ʲ��Υե��������������롣
#
#            1) InDict.actran : �����ȥޥȥ�������ɽ
#                 ((OutPut��Fail��Number)��(W_CHAR)^Number��(Offset)^Number)+
#            2) InDict.acdata : Ĺ�����ʻ��ֹ������٤��Ȥ���
#                 (Length��Part��Freq)+
#
# ����ˡ : MakeInDictAC.perl
#
# ��  �� : MakeInDictAC.perl
#
# ������ : �����ȥޥȥ�������ɽ�ˤ����� Number �������ξ����ϥ����ꥢ�饤�������ȤΤ�
#          ���Υ��ߡ�(2byte)���������롣
#
#          STEP 0 �ξ��硢 SS20(70MHz) ���������֤����ä�


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use File::Basename;
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
#                        %MotPos ������
#-------------------------------------------------------------------------------------

%MotPos = ();                                     # ɽ�� -> (�ʻ��ֹ�, �и�����)+
foreach $part (2 .. $WordIntStr->size-1){         # UT �� BT ������
    $word = $WordIntStr->str($part);
    $freq = $WordMarkov->_1gram($part);
    $MotPos{$word} .= pack("II", $part, $freq);
#    printf(STDERR "F(%s) = %d\n", $word, $freq);
}


#-------------------------------------------------------------------------------------
#                        %ACTran ������
#-------------------------------------------------------------------------------------

warn "\%ACTran ������\n";

# %ACTran �� context(�ڤΥΡ���) �������������Ƥ���ʸ�� (W_CHAR)+ �ؤμ���
foreach $word (keys(%MotPos)){                    # ���Ƥΰۤʤ�ɽ�����Ф����롼��
#    printf(STDERR "word = %s\n", $word);
    for ($length = 0; $length < length($word); $length += 2){
        $contex = substr($word, 0, $length);      # �ڤΰ���
        $nextwc = substr($word, $length, 2);      # ����ʸ��
#        printf(STDERR "  contex = %s, nextwc = %s", $contex, $nextwc);
        for ($i = 0; $i < length($ACTran{$contex}); $i += 2){
#            printf(STDERR " %s?", substr($ACTran{$contex}, $i, 2));
            last if ($nextwc eq substr($ACTran{$contex}, $i, 2));
        }
        if ($i == length($ACTran{$contex})){      # ̤��Ͽ�ξ���
            $ACTran{$contex} .= $nextwc;
#            printf(STDERR "  Data added\n");
        }
    }
    (defined($ACTran{$word})) || ($ACTran{$word} = "");
}


#-------------------------------------------------------------------------------------
#                        $ACTran ���ΰ����ݤ� $OutPut ������
#-------------------------------------------------------------------------------------

warn "\$ACTran ���ΰ����ݤ� \$OutPut ������\n";

# $ACTran{$contex} �ϥΡ��� $contex �� $ACTran �ˤ��������֤˾��񤭤�����

$SENTINEL = pack("III", 0, 0, 0);                 # ����ɽ����ʼ
$OutPut = $SENTINEL;                              # (Length��Part��Freq)+
($contex, $data) = ("", $ACTran{""});
$data = join("", sort($data =~ m/(..)/g));        # EUC �����ɽ����¤��Ѥ���
$number = length($data)/2;                        # �ҥΡ��ɤο�
($number%2 == 0) || ($data .= pack("S", 0xffff)); # �����ꥢ�饤�������ȤΤ����Υ��ߡ�
$ACTran = pack("III", 0, 0, $number) . $data . (pack("I", 0) x $number);
$ACTran{$contex} = pack("I", 0);                  # �Ρ��ɤ� $ACTran �ˤ���������
while (($contex, $data) = each(%ACTran)){         # ����ɽ�κ����ȳ��ϰ��֤η׻�
    next if ($contex eq "");                      # �����Ѥ�
    $data = join("", sort($data =~ m/(..)/g));    # EUC �����ɽ����¤��Ѥ���
#    printf(STDERR "%s [%s]\n", $contex, join(" ", $data =~ m/(..)/g));
    $ACTran{$contex} = pack("I", length($ACTran));# �Ρ��ɤ� $ACTran �ˤ���������
    for ($temp = "", $len = length($contex); $len > 0; $len -= 2){
        $dict = $MotPos{substr($contex, -$len, $len)};
        for ($i = 0; $i < length($dict); $i += 8){
            $temp .= pack("I", int($len/2)) . substr($dict, $i, 8);
        }
    }
    if ($temp eq ""){                             # ���ΰ��֤ǽ��������Ǥ��ʤ�����
        $ACTran .= pack("I", 0);
    }else{                                        # ���ΰ��֤ǽ��������Ǥ���������
        $ACTran .= pack("I", length($OutPut));
        $OutPut .= $temp . $SENTINEL;
    }
    $number = length($data)/2;                    # �ҥΡ��ɤο�
    ($number%2 == 0) || ($data .= pack("S", 0xffff)); # ���饤�������ȤΤ����Υ��ߡ�
    $ACTran .= pack("II", 0, $number) . $data . (pack("I", 0) x $number);
}


#-------------------------------------------------------------------------------------
#                        $ACTran �δ���
#-------------------------------------------------------------------------------------

warn "\$ACTran �δ���\n";

while (($contex, $node) = each(%ACTran)){         # ����ɽ�δ���
    $node = unpack("I", $node);
    $number = unpack("I", substr($ACTran, $node+8, 4));

    # fail pointer ������
    for ($len = length($contex)-2; $len > 0; $len -= 2){
        last if (defined($ACTran{substr($contex, -$len, $len)}));
    }
    substr($ACTran, $node+4, 4) = $ACTran{substr($contex, -$len, $len)};

    # �ҥΡ��ɤ�����
    $offset = ($number%2 == 0) ? $number*2+12 : $number*2+2+12;
    for ($i = 0; $i < $number; $i++){
        $nextwc = substr($ACTran, $node+12+$i*2, 2);
        substr($ACTran, $node+$offset+$i*4, 4) = $ACTran{$contex . $nextwc};
    }
}

printf(STDERR "InDict.actran %d[KB]\n", length($ACTran)/1024);
$ACTRAN = "> InDict.actran";
open(ACTRAN) || die "Can't open $ACTRAN: $!\n";
print ACTRAN $ACTran;
close(ACTRAN);

printf(STDERR "InDict.acdata %d[KB]\n", length($OutPut)/1024);
$ACDATA = "> InDict.acdata";
open(ACDATA) || die "Can't open $ACDATA: $!\n";
print ACDATA $OutPut;
close(ACDATA);


#-------------------------------------------------------------------------------------
#                        ���񸡺��μ¸�
#-------------------------------------------------------------------------------------

warn "���񸡺��μ¸�\n";

select(STDERR);
$_ = "�˽����ѵ�������ˡ���ޤ��������롣";
print $_, "\n";
for ($node = 0, $suf = 0; $suf < length; $suf += 2){
#    printf(STDERR "code = %s\n", substr($_, $suf, 2));
    LOOP: while (1){

        ($fail, $number) = unpack("II", substr($ACTran, $node+4, 8));
#        printf(STDERR "fail = %4d, number = %s\n", $fail, $number);

        ($number > 0) || ($node = $fail, next);   # �ҥΡ��ɤ��ʤ�����

        ($gauche, $droite) = (-1, $number);
        while ($gauche+1 < $droite){
            $centre = int(($gauche+$droite)/2);
            $nextwc = substr($ACTran, $node+12+$centre*2, 2);
            if ($nextwc lt substr($_, $suf, 2)){
#                printf(STDERR "%s lt %s\n", $nextwc, substr($_, $suf, 2));
                $gauche = $centre;
                next;
            }
            if ($nextwc gt substr($_, $suf, 2)){
#                printf(STDERR "%s gt %s\n", $nextwc, substr($_, $suf, 2));
                $droite = $centre;
                next;
            }
#            printf(STDERR "%s eq %s\n", $nextwc, substr($_, $suf, 2));
            $offset = ($number%2 == 0) ? $number*2+12 : $number*2+2+12;
            $node = unpack("I", substr($ACTran, $node+$offset+$centre*4, 4));
            last LOOP;
        }
        ($node == $fail) && last LOOP;            # ̵�¥롼�פ˴٤��ʤ�����
        $node = $fail;
    }

    $outpos = unpack("I", substr($ACTran, $node, 4));
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


#=====================================================================================
#                        END
#=====================================================================================
