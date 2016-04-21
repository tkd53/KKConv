#!/usr/bin/env perl
#=====================================================================================
#                        SArrayWordCand.perl
#                             by Shinsuke Mori
#                             Last change : 7 June 2008
#=====================================================================================

# ��  ǽ : ñ���θ����򻻽Ф���
#
# ����ˡ : SArrayWordCand.perl (STEP) (FILESTEM) (N)
#
# ��  �� : SArrayWordCand.perl 0 91
#
# ������ : �ʲ���������������(�⡼�餢�����ε���Ĺ)���㤤���˽��Ϥ���
#
#               1       f(w)
#            - --- log ------ P(y|w)
#              |y|     ��f(w)
#
#          ���θ��Ͻ�������
#          ��ʸ�����ɤߤϣ��⡼���ʲ��Τ�
#          �������ʸ�, �򤸤���


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use POSIX;
use English;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/SLM/lib/perl",
        "$HOME/SLM/text/lib/perl");

require "Help.pm";
require "Math.pm";
require "Char.pm";
require "MinMax.pm";

require "SArray.pm";
require "StochSegText.pm";

require "class/IntStr.pm";
require "class/MarkovHashMemo.pm";


#-------------------------------------------------------------------------------------
#                        ���̤��ѿ����ؿ����������ɤ߹���
#-------------------------------------------------------------------------------------

use constant VRAI => 1;                           # ��
use constant FAUX => 0;                           # ��

do "dofile/CrossEntropyBy.perl";
do "dofile/CrossEntropyByWord.perl";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

((@ARGV == 3) && ($ARGV[0] ne "-help")) || &Help($0);

$STEP = 4**shift;                                 # �ؽ������ѥ���ʸ�Υ��ƥå�
$STEM = shift;
$GRAM = shift;                                    # n of n-gram
$PATH = dirname($STEM);
$STEM = basename($STEM);


#-------------------------------------------------------------------------------------
#                        ��ͭ���ѿ�������
#-------------------------------------------------------------------------------------

require "Char.pm";

@TYPESTRING = ("������", "������", "������", "ʿ��̾", "�Ҳ�̾", "������");
$CharType = scalar(@TYPESTRING);                  # ʸ���μ���
%Char = (map(($_ => 1), @SIGN),                   # ������ undef (= 0)
         map(($_ => 2), @NUMBER),
         map(($_ => 3), @HIRAGANA),
         map(($_ => 4), @KATAKANA),
         map(($_ => 5), (@LATINU, @LATIND, @GREEKU, @GREEKD, @CYRILU, @CYRILD)));

%ExChar = map(($_ => 1), ("BT", grep($_ ne "��", @SIGN), @LATINU,
              @LATIND, @NUMBER, @GREEKU, @GREEKD, @CYRILU, @CYRILD));

$KATAKANA = join("|", @KATAKANA);


#-------------------------------------------------------------------------------------
#                        ��ͭ���ѿ�������
#-------------------------------------------------------------------------------------

@WordMarkovTest = (&Morphs2Words($MorpMarkovTest))[0 .. 1];

$STOPCHAR = "$HOME/SLM/lib/StopChar.text";

$TEXT = $PATH . "/" . $STEM . ".text";                          # �ƥ�����


#-------------------------------------------------------------------------------------
#                        ñ��������
#-------------------------------------------------------------------------------------

$TANKAN = "SLM/vir/KKConv/lib/tankan";
#@FILE = qw( JIS1.text JIS2.text Kana.text Kigo.text Suji.text );
@FILE = qw( JIS1.text JIS2.text Kana.text );
%TANKAN = ();
$CharYomi = 1;                                    # BT ��ʬ
foreach $FILE (@FILE){
    $FILE = join("/", $HOME, $TANKAN, $FILE);
    open(FILE) || die "Can't open $FILE: $!\n";
    while (chop($_ = <FILE>)){                    # main loop
        (m/^\#/) && next;                         # �������ȹ�
        (m/^\s*$/) && next;                       # ����
        ($char, @yomi) = split;
        @yomi = grep((&Mora($_) < 4), @yomi);     # ��ʸ�����ɤߤϣ��⡼���ʲ��Τ�
        $TANKAN{$char} = [@yomi];
        $CharYomi += @yomi;
    }
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        ̤�θ��ɤߥ��ǥ�
#-------------------------------------------------------------------------------------

$YOMIROOT = "$HOME/SLM/EDR/Yomi/Morp-2/Step0";

$FILE = "$YOMIROOT/TankanIntStr.text";
$TankanIntStr = new IntStr($FILE);
$CharYomi -= ($TankanIntStr->size()-1);

$LAMBDA = "$YOMIROOT/TankanLambda";
open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
@LforTankan = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
close(LAMBDA);

$FILE = "$YOMIROOT/TankanMarkov";
$TankanMarkov = new MarkovHashMemo($TankanIntStr->size, $FILE);


#-------------------------------------------------------------------------------------
#                        ̤�θ����ǥ�
#-------------------------------------------------------------------------------------

$CHARROOT = "$HOME/SLM/EDR/Word-2/Step0";

$FILE = "$CHARROOT/CharIntStr.text";
$CharIntStr = new IntStr($FILE);
$CharUT = $CharAlphabetSize-($CharIntStr->size-2);

$LAMBDA = "$CHARROOT/CharLambda";
open(LAMBDA) || die "Can't open $LAMBDA: $!\n";
@LforChar = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
close(LAMBDA);

$FILE = "$CHARROOT/CharMarkov";
$CharMarkov = new MarkovHashMemo($CharIntStr->size, $FILE);


#-------------------------------------------------------------------------------------
#                        @StopChar ������
#-------------------------------------------------------------------------------------

open(STOPCHAR) || die "Can't open $STOPCHAR: $!\n";
warn "Reading $STOPCHAR in Memory\n";
chop foreach (@StopChar = <STOPCHAR>);            # ���Ե����ν���
close(STOPCHAR);
%StopChar = map(($_ => 1), (@StopChar, $BT));     # BT ���ä��Ƥ�����������
#warn join("\n", @StopChar), "\n";                 # for debug


#-------------------------------------------------------------------------------------
#                        BTProb �η׻�
#-------------------------------------------------------------------------------------

$BTPROB = "BTProb";                               # ñ�����ڤ��γ�Ψ�ե�����
(-r $BTPROB) || &CalcBTProb($BTPROB);


#-------------------------------------------------------------------------------------
#                        0-gram �η׻�
#-------------------------------------------------------------------------------------

$G0FILE = $STEM . ".0-gram";    # ñ�� 0-gram �ե�����
(-r $G0FILE) || &CalcCraw0g($G0FILE, $TEXT);


#-------------------------------------------------------------------------------------
#                        $text ������
#-------------------------------------------------------------------------------------

$text = new StochSegText(join("/", $PATH, $STEM), $BTPROB, $G0FILE);

#$freq = $text->Freq("����");                      # $text �Υƥ���
#printf("F(����) = %f\n", $freq);
#$freq = $text->Freq("��", "��");                      # $text �Υƥ���
#printf("F(�� ��) = %f\n", $freq);


#-------------------------------------------------------------------------------------
#                        $WordIntStr ������
#-------------------------------------------------------------------------------------

(-e ($FILE = "WordIntStr.text")) ||               # �ե����뤬���뤫��  �ʤ����к��롣
    &WordIntStr($FILE, map(sprintf($CTEMPL, $_), @Kcross));
$WordIntStr = new IntStr($FILE);

$PAT1 = join("|", $WordIntStr->strs());           # ���θ��Υѥ�����
$PAT2 = join("|", grep((length >= 4), $WordIntStr->strs())); # ��ʸ���ʾ�

#$word = "����";
#print $word, "\n";
#&calc($word);
#exit(0);


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

@HEAD = qw( �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� );
$HEAD = join("|", @HEAD);

$LENGTH = 6;                                      # �������ʤΤߤβ���

$sarray = $text->sarray();

for ($posi = 0, $word = ""; $posi < $sarray->size(); $posi++){
    $string = $sarray->substr($sarray->SArray($posi), $GRAM);
    ($string eq $word) && next;
    $word = $string;
    ($word =~ m/^($HEAD)/) && next;
    if ($GRAM < $LENGTH){
        &calc($word) unless (grep($ExChar{$_}, ($word =~ m/(..)/g)));
    }else{
        &calc($word) if ($word =~ m/^($KATAKANA)+$/);
    }
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#-------------------------------------------------------------------------------------
#                        calc
#-------------------------------------------------------------------------------------

sub calc{
    (@_ == 1) || die;
    my($word) = shift;

#    ($word =~ m/^($PAT1)+$/) && return;           # ���θ����ˤʤ����Τ���������
    ($word =~ m/^($PAT1)$/) && return;            # ���θ�����������
    ($word =~ m/^($PAT2)+$/) && return;           # ��ʸ���ʾ��δ��θ���������

    my($prob) = $text->Prob($word);               # ���� 1-gram ��Ψ

#    printf("%8.4f %s \n", -log($prob), $word);
#    return;

    my($UWlogP) = &UWlogP($word);

    my(@char) = ($word =~ m/(..)/g);

    @suff = (0) x @char;                          # �ɤߤ�ź��
    @SUFF = map(scalar(@{$TANKAN{$_}}), @char);   # ź���ξ���

    (grep($_ == 0, @SUFF)) && return;             # ñ���ˤʤ�ʸ��������

#    printf("%s %f\n", $word, -log($text->Prob($word)));

    do {                                          # ���Ƥ� [ɽ��, �ɤ�] ���ȹ礻
        my(@elem) = ();
        for ($i = 0; $i < @suff; $i++){           # ��ʸ�����֤��Ф����롼��
            push(@elem, join("/", $char[$i], ${$TANKAN{$char[$i]}}[$suff[$i]]));
        }
        my($yomi) = join("", map((split("/"))[1], @elem));
        my($logP) = &ent(@elem)-$UWlogP;
        my($mora) = &Mora($yomi);
        ($mora >= 3) || next;                     # ���⡼���ʾ�
        printf("%8.4f %s %s\n", (-log($prob)+$logP)/$mora, $word, join(" ", @elem));
    } while (&inc(\@suff, \@SUFF));
    
    return;
}


#-------------------------------------------------------------------------------------
#                        inc
#-------------------------------------------------------------------------------------

# ��  ǽ : ź���Υ��󥯥�������
#
# ������ : �ʤ�

sub inc{
    (@_ == 2) || die;
    my($suff, $SUFF) = @_;

    for ($i = 0; $i < @$suff; $i++){
        $$suff[$i]++;
        if ($$suff[$i] == $$SUFF[$i]){            # ���夬��
            $$suff[$i] = 0;
        }else{
            return(1);
        }
    }

    return(0);                                    # ���Ƥ��ȹ礻���Ԥ�����
}


#-------------------------------------------------------------------------------------
#                        ent
#-------------------------------------------------------------------------------------

# ��  ǽ : �����ȥ��ԡ��η׻�
#
# ������ : �ʤ�

sub ent{
    (@_ > 0) || die;
    my(@elem) = @_;

    my($logP) = 0;
    my($Tnum) = scalar(@elem)+1;

    my(@state) = ($TankanIntStr->int($BT)) x 1;
    foreach $char (@elem, $BT){                   # ʸ��ñ�̤Υ롼��
        push(@state, $TankanIntStr->int($char));
        if ($TankanMarkov->_1gram($state[0]) > 0){
            $p0 = 1/$TankanIntStr->size();
            $p1 = $TankanMarkov->_1prob($state[0]);
            $p2 = $TankanMarkov->_2prob(@state);
            $prob = $LforTankan[0]*$p0+$LforTankan[1]*$p1+$LforTankan[2]*$p2;
        }else{
            $p0 = 1/$TankanIntStr->size();
            $p1 = $TankanMarkov->_1prob($state[0]);
            $prob = $LforTankan[3]*$p0+$LforTankan[4]*$p1;
        }
        $logP += -log($prob);
        shift(@state);
    }

    return($logP);
}


#-------------------------------------------------------------------------------------
#                        Mora
#-------------------------------------------------------------------------------------

# ��  ǽ : �ɤߤ����������⡼�������֤�
#
# ������ : ���⡼���ˤʤ��ʤ�ʸ���Υѥ����� $NoMoraChar �򻲾�

sub Mora{
    (@_ == 1) || die;
    my($yomi) = @_;
    my($mora) = 0;                                # �⡼����

    my(@NoMoraChar) = qw( �� �� �� �� �� �� �� �� �� ); # ���⡼���ˤʤ��ʤ�ʸ��
    my($NoMoraChar) = join("|", @NoMoraChar);

    foreach $char ($yomi =~ /(..)/g){
        ($char =~ m/^($NoMoraChar)$/) && next;
        $mora++;
    }

#    printf("%s -> %d\n", $yomi, $mora);
    
    return($mora);
}


#=====================================================================================
#                        END
#=====================================================================================
