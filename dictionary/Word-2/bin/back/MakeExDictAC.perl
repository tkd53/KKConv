#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                        MakeExDictAC.perl
#                             by Shinsuke MORI
#                             Last change : 2 December 2006
#=====================================================================================

# ��  ǽ : MorpIntStr.text �� MorpMarkov.db ����̤�θ����ǥ��ˤ������θ���������Ψ�ι�
#          ���ͤ��׻��������������θ��Ф�������ʬ���롣�ʲ��Υե��������������롣
#
#            1) ExDict.actran : �����ȥޥȥ�������ɽ
#                 ((OutPut��Fail��Number)��(W_CHAR)^Number��(Offset)^Number)+
#            2) ExDict.acdata : Ĺ�����ʻ��ֹ������п���Ψ�ͤ��Ȥ���
#                 (Length��Part��LogP)+
#
# ����ˡ : MakeExDictAC.perl (filename)
#
# ��  �� : MakeExDictAC.perl ExDict.text
#
# ������ : (filestem) �γƹԤ� "ɽ��/�ʻ�\n" �ȤʤäƤ��ʤ����Фʤ��ʤ���


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

((@ARGV == 1) && ($ARGV[0] ne "-help")) || &Help($0);
print STDERR join(" ", basename($0), @ARGV), "\n";

$EXDICT = shift;                                  # ���������ե�����


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ����ؿ����������ɤ߹���
#-------------------------------------------------------------------------------------

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        $WordIntStr ������
#-------------------------------------------------------------------------------------

$WordIntStr = new IntStr("WordIntStr.text");


#-------------------------------------------------------------------------------------
#                        @EXDICT ������ (���θ��ν���)
#-------------------------------------------------------------------------------------

%ExDict = ();
open(EXDICT) || die "Can't open $EXDICT: $!\n";
while (chop($word = <EXDICT>)){
    next if ($WordIntStr->int($word) ne $WordIntStr->int($UT));
    $ExDict{$word} = 1;                           # �����������ꥹ�Ȥ��ɲ�
}
close(EXDICT);
@ExDict = keys(%ExDict);

print STDERR "�������񥨥��ȥ꡼��: ", scalar(@ExDict), "\n";
(scalar(@ExDict) > 0) || die;

#printf(STDERR "%s\n", "-" x 80);
#foreach $word (@ExDict){
#    printf(STDERR "  %s\n", $word);
#}


#-------------------------------------------------------------------------------------
#                        ʸ�� 2-gram ���ǥ����ɤ߹���
#-------------------------------------------------------------------------------------

($CharIntStr, $CharMarkov, @LforChar) = &Read2gramModel("Char");
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);

#$CharMarkov->test($CharIntStr, @CharMarkovTest);


#-------------------------------------------------------------------------------------
#                        %MotPos ������
#-------------------------------------------------------------------------------------

warn "���θ������ѳ�Ψ�η׻�\n";

$prob = 0;                                        # ����������������������Ψ
foreach $word ($WordIntStr->strs){
    ($word ne $UT) || next;
    ($word ne $BT) || next;
    $prob += exp(-&UWlogP($word));                # ������������������Ψ�βû�
#    printf("%s %6.4f\n", $word, &UWlogP($word));  # for debug
}

%MotPos = ();                                     # ɽ�� -> (�ʻ��ֹ�, ������Ψ)+
$part = 0;                                        # �ʻ��ֹ��ϣ�
$prob /= scalar(@ExDict);                         # ��������������ʬ�����Ȥ��γ�Ψ��
#    printf(STDERR "prob[%s] = %20.18f\n", $Part, $prob); # for debug
foreach $word (@ExDict){
    $logP = -log(exp(-&UWlogP($word))+$prob);     # ������Ψ
#        printf(STDERR "%20s %6.3f\n", $word, $logP); # for debug
    $MotPos{$word} .= pack("Id", $part, $logP);
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

$SENTINEL = pack("IId", 0, 0, 0.0);               # ����ɽ����ʼ
$OutPut = $SENTINEL;                              # (Length��Part��logP)+
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
        for ($i = 0; $i < length($dict); $i += 12){
            $temp .= pack("I", int($len/2)) . substr($dict, $i, 12);
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

printf(STDERR "ExDict.actran %d[KB]\n", length($ACTran)/1024);
$ACTRAN = "> ExDict.actran";
open(ACTRAN) || die "Can't open $ACTRAN: $!\n";
print ACTRAN $ACTran;
close(ACTRAN);

printf(STDERR "ExDict.acdata %d[KB]\n", length($OutPut)/1024);
$ACDATA = "> ExDict.acdata";
open(ACDATA) || die "Can't open $ACDATA: $!\n";
print ACDATA $OutPut;
close(ACDATA);


#-------------------------------------------------------------------------------------
#                        ���񸡺��μ¸�
#-------------------------------------------------------------------------------------

warn "���񸡺��μ¸�\n";

select(STDERR);
$_ = "�˽����ѵ���aaˡ���ޤ�ca���롣";
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
    for ($off = 0; ; $off += 16){
        ($len, $pos, $log) = unpack("IId", substr($OutPut, $outpos+$off, 16));
        ($len > 0) || last;
        printf("%s%s/%s(%6.3f)\n", " " x (2+$suf-$len*2),
               substr($_, 2+$suf-$len*2, $len*2), $WordIntStr->str($pos), $log);
    }
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

warn "Done\n";
exit(0);


#-------------------------------------------------------------------------------------
#                        ReadLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ���������ե����뤫�����ַ������ɤ߹���

sub ReadLambda{
#    warn "main::ReadLambda\n";
    (@_ == 1) || die;
    my($FILE) = shift(@_);

    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    @LAMBDA = map($_+0.0, split(/[ \t\n]+/, <FILE>));
    close(FILE);

    return(@LAMBDA);
}


#=====================================================================================
#                        END
#=====================================================================================
