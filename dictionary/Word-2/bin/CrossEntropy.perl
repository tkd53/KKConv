#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                       CrossEntropy.perl
#                             bShinsuke Mori
#                             Last change 24 June 2014
#=====================================================================================

# ��  ǽ : ñ��(ɽ��) 2-gram ���Ѥ��� Cross Entropy ���׻����롣
#
# ����ˡ : CrossEntropy.perl STEP [TEST]
#
# ��  �� : CrossEntropy.perl 0 ../../corpus/TRL10.morp
#
# ������ : (filestem).morp �� "ɽ��/�ʻ� ..." �ȤʤäƤ��ʤ����Фʤ��ʤ���
#          �Կ��� 4**ARGV[0] �ǳ����ڤ���ʸ�������Ѥ��Ƴؽ����롣


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use English;
use File::Basename;
unshift(@INC, "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl");

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

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�
$TEST = (@ARGV) ? shift : undef;


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ����ؿ����������ɤ߹���
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # ��
use constant FAUX => 0;                           # ��

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        ��ͭ���ѿ�������
#-------------------------------------------------------------------------------------

$MO = 1;                                          # �ޥ륳�ե��ǥ��μ���

@WordMarkovTest = (&Line2Units($WordMarkovTest))[0 .. $MO];
@CharMarkovTest = (split(" ", $CharMarkovTest))[0 .. $MO];


#-------------------------------------------------------------------------------------
#                        $WordIntStr ������
#-------------------------------------------------------------------------------------

(-e ($FILE = "WordIntStr.text")) ||               # �ե����뤬���뤫��  �ʤ����к��롣
    &WordIntStr($FILE, map(sprintf($CTEMPL, $_), @Kcross));
$WordIntStr = new IntStr($FILE);

#goto CharMarkov;


#-------------------------------------------------------------------------------------
#                        ñ���ޥ륳�ե��ǥ������ַ����ο���
#-------------------------------------------------------------------------------------

$LAMBDA = "WordLambda";                           # ���ַ����Υե�����
(-r $LAMBDA) || &CalcWordLambda($MO, $LAMBDA);    # �ե����뤬�ʤ����з׻�

@LforWord = &ReadLambda($LAMBDA);
#exit(0);


#-------------------------------------------------------------------------------------
#                        $WordMarkov ������
#-------------------------------------------------------------------------------------

if (-e (($FILE = "WordMarkov") . $MarkovHash::SUFFIX)){
    $WordMarkov = new MarkovHashMemo($WordIntStr->size, $FILE);
#    $WordMarkov = new MarkovHashDisk($WordIntStr->size, $FILE);
}else{
    $WordMarkov = new MarkovHashMemo($WordIntStr->size);
    &WordMarkov($WordMarkov, map(sprintf($CTEMPL, $_), @Kcross));
#    $DIRE = "/dev/shm";                           # ���֤��������Τǰ�ö RAM DISK ��
#    $WordMarkov->put("$DIRE/$FILE");
    $WordMarkov->put($FILE);
#    system("/bin/mv $DIRE/$FILE.db .");
}
$WordMarkov->test($WordIntStr, @WordMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        $CharIntStr ������
#-------------------------------------------------------------------------------------

CharMarkov:

(-e ($FILE = "CharIntStr.text")) ||               # �ե����뤬���뤫��  �ʤ����к��롣
    &CharIntStr($FILE, map(sprintf($CTEMPL, $_), @Kcross));
$CharIntStr = new IntStr($FILE);

$CharUT = $CharAlphabetSize-($CharIntStr->size-2);# ̤��ʸ���ο�


#-------------------------------------------------------------------------------------
#                        ʸ���ޥ륳�ե��ǥ������ַ����ο���
#-------------------------------------------------------------------------------------

$LAMBDA = "CharLambda";                           # ���ַ����Υե�����
(-r $LAMBDA) || &CalcCharLambda(1, $LAMBDA);      # �ե����뤬�ʤ����з׻�

@LforChar = &ReadLambda($LAMBDA);


#-------------------------------------------------------------------------------------
#                        $CharMarkov ������
#-------------------------------------------------------------------------------------

if (-e (($FILE = "CharMarkov") . $MarkovHash::SUFFIX)){
    $CharMarkov = new MarkovHashMemo($CharIntStr->size, $FILE);
}else{
    $CharMarkov = new MarkovHashMemo($CharIntStr->size);
    &CharMarkov($CharMarkov, map(sprintf($CTEMPL, $_), @Kcross));
    $CharMarkov->put($FILE);
}
$CharMarkov->test($CharIntStr, @CharMarkovTest);
warn "\n";


#-------------------------------------------------------------------------------------
#                        @EXDICT ������ (���θ��ν���)
#-------------------------------------------------------------------------------------

goto NoExDict;

$EXDICT = "ExDict.text";

@ExDict = ();
open(EXDICT) || die "Can't open $EXDICT: $!\n";
while (chop($word = <EXDICT>)){
    next if ($WordIntStr->int($word) ne $WordIntStr->int($UT));
    push(@ExDict, $word);                         # �����������ꥹ�Ȥ��ɲ�
}
close(EXDICT);


#----------------------- ���θ������ѳ�Ψ�η׻� --------------------------------------

$prob = 0;                                        # ����������������������Ψ
foreach $word ($WordIntStr->strs){
    $prob += exp(-&UWlogP($word));                # ������������������Ψ�βû�
#    printf("STDERR %s %6.4f\n", $word, &UWlogP($word));  # for debug
}


#----------------------- %ExDict ������ ----------------------------------------------

%ExDict;

$prob /= scalar(@ExDict);                         # ��������������ʬ�����Ȥ��γ�Ψ��
#printf("STDERR prob = %20.18f\n", $prob);                # for debug
foreach $word (@ExDict){
    $logP = -log(exp(-&UWlogP($word))+$prob);     # ������Ψ
#    printf(STDERR "%20s %6.3f\n", $word, $logP);  # for debug
    $EXDICT{$word} = $logP;
}

NoExDict:


#-------------------------------------------------------------------------------------
#                        �����ȥ��ԡ��η׻�
#-------------------------------------------------------------------------------------

$FLAG = VRAI;                                     # ʸ���Υ�����ɽ��
$FLAG = FAUX;

$CORPUS = $TEST ? $TEST : sprintf($CTEMPL, 10);   # �ƥ��ȥ����ѥ�
open(CORPUS) || die "Can't open $CORPUS: $!\n";
warn "Reading $CORPUS\n";
for ($logP = $UMlogP = 0, $Cnum = $Wnum = 0; <CORPUS>; ){
#    print;
#    @word = split(/[ \-]/);
#    $_ = join(" ", @word), "\n";
    $cnum = scalar(&Line2Chars($_))+1;            # ͽ¬�оݤ�ʸ����(ʸ���������ޤ�)
    $wnum = scalar(&Line2Units($_))+1;            # ͽ¬�оݤ�ñ����(ʸ���������ޤ�)

    $logp = $UMlogp = 0;
    my(@stat) = ($WordIntStr->int($BT)) x $MO;
    foreach $word (&Line2Units($_), $BT){         # ñ��ñ�̤Υ롼��
        push(@stat, $WordIntStr->int($word));
#        printf(STDERR "f(%s) = %d\n", $word, $WordMarkov->_1gram($word));
        $logp += -log($WordMarkov->prob(@stat, @LforWord));
        if ($stat[1] == $WordIntStr->int($UT)){   # ̤�θ��ξ���
            $temp = defined($EXDICT{$word}) ? $EXDICT{$word} : &UWlogP($word);
            $UMlogp += $temp;
            $logp += $temp;
        }
        shift(@stat);
    }

    $FLAG && printf(STDERR "%s", $_);
    $FLAG && printf(STDERR "  ʸ���� = %d, H = %8.6f\n", $cnum, $logp/$cnum/log(2));
    $FLAG && printf(STDERR "  ñ���� = %d, PP = %8.6f\n\n", $wnum, exp($logp/$wnum));

    $Cnum += $cnum;
    $Wnum += $wnum;
    $logP += $logp;
    $UMlogP += $UMlogp;
}
close(CORPUS);

printf(STDERR "ʸ���� = %d, H = %8.6f ", $Cnum, $logP/$Cnum/log(2));
printf(STDERR "(̤�θ���ɽ��ͽ¬: %8.6f)\n", $UMlogP/$Cnum/log(2));
printf(STDERR "ñ���� = %d, PP = %8.6f\n", $Wnum, exp($logP/$Wnum));


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#=====================================================================================
#                        END
#=====================================================================================
