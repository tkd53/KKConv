#=====================================================================================
#                       CrossEntropyByPart.perl
#                             bShinsuke Mori
#                             Last change 19 June 2010
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        PartIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ��ʻ�ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub PartIntStr{
    warn "main::PartIntStr\n";
    my($FILE) = shift;

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, $BT, @Part), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        PartMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ������ǥ�٥�Υޥ륳�ե�ǥ����������

sub PartMarkov{
    warn "main::PartMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @stat = map($PartIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat)); 
        }
        close(CORPUS);
    }
    foreach (@Part){                              # F(UT) > 0 ���ݾڤ��� (floaring)
        $markov->inc(($MorpIntStr->int($_)) x ($MO+1));
    }
}


#-------------------------------------------------------------------------------------
#                        CalcPartLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ������ǥ�٥�Υޥ륳�ե�ǥ����������

sub CalcPartLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե�ǥ�μ���
    my($LAMBDA) = shift;                          # ��ַ����Υե�����̾

    my(@PartMarkov);                              # �����Х�ǡ�������ѤΥ�ǥ�

    foreach $n (@Kcross){                         # �������ѤΥޥ륳�ե�ǥ������
        $PartMarkov[$n] = new MarkovHashMemo($PartIntStr->size);
#        $FILE = sprintf("PartMarkov%02d", $n);
#        $PartMarkov[$n] = new MarkovHashDisk($PartIntStr->size, $FILE);
        &PartMarkov($PartMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $PartMarkov[$n]->test($PartIntStr, @PartMarkovTest);
#        $PartMarkov[$n]->put(sprintf("PartMarkov%02d", $n));
        warn "\n";
    }

    my(@Tran);                                    # [(������, ����)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack �� TEMPLATE
    foreach $n (@Kcross){                         # �����ѥ��������ɤ߹���
        my($FILE) = sprintf($CTEMPL, $n);
        open(FILE, $FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        my(%Tran);                                # ������ => ����
        while (<FILE>){
            ($.%$STEP == 0) || next;
            my(@stat) = map($PartIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $Tran{pack($PT, @stat[$_-$MO .. $_])}++, ($MO .. $#stat)); 
        }
        close(FILE);

        $Tran[$n] = [];                           # (������, ����)+
        while (($key, $val) = each(%Tran)){
            push(@{$Tran[$n]}, [unpack($PT, $key), $val]);
        }
        undef(%Tran);
    }

    my($TEMPLATE) = "%6.4f";                      # ��ַ�������ӷ��
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EM���르�ꥺ��ν����
    do {                                          # EM���르�ꥺ��Υ롼��
        @LforPart = @Lnew;                    # �����ȥ�å���
        @Lnew = (0) x @LforPart;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $PartMarkov[$n]->OneIteration($Tran[$n], @LforPart);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforPart));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforPart));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforPart));
    
    undef(@PartMarkov);

    my($FILE) = "> $LAMBDA";                          # ��ַ����ե����������
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforPart)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        MorpVector
#-------------------------------------------------------------------------------------

# ��  ǽ : �Ʒ����Ǥ����٤�٥��ȥ���������롣
#
# ��  �� : @MorpVector ������ѿ��Ǥ��롣

sub MorpVector{
    warn "main::MorpVector\n";
    my(@CORPUS) = @_;
    foreach $CORPUS (@CORPUS){
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $morp (split){
                $MorpVector[$MorpIntStr->int($morp)]++;
            }
        }
        close(CORPUS);
    }
}


#=====================================================================================
#                        END
#=====================================================================================
