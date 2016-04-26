use bytes;
#=====================================================================================
#                       CrossEntropyByMorp.perl
#                             bShinsuke Mori
#                             Last change 6 June 2010
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        Line2Units
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ������ʸ���ɤ߹��ߡ�ʸ���Υꥹ�Ȥ��֤���
#
# ��  �� : ʸ�� "ɽ��/????..." �ȤʤäƤ���ɬ�פ����롣

sub Line2Units{
    return(split(" ", shift));
}


#-------------------------------------------------------------------------------------
#                        Line2Chars
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ������ʸ���ɤ߹��ߡ�ʸ���Υꥹ�Ȥ��֤���
#
# ��  �� : ʸ�� "ɽ��/????..." �ȤʤäƤ���ɬ�פ����롣

sub Line2Chars{
    return(map(m/(..)/g, map((split("/"))[0], split(" ", shift))));
}


#-------------------------------------------------------------------------------------
#                        UMlogP
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ����������Ǥ�ʸ������п���Ψ���֤���
#
# ��  �� : �����Х��ѿ�($BT, $CharIntStr, $LforChar, $CharMarkov)���ꤷ�Ƥ��롣

sub UMlogP{
    my($morp) = shift;

    my($part) = $Part{(split("/", $morp))[1]};

    my($logP) = 0;
    my(@char) = ($CharIntStr[$part]->int($BT)) x 1;
    foreach (&Morphs2Chars($morp), $BT){          # ʸ��ñ�̤Υ롼��
        push(@char, $CharIntStr[$part]->int($_));
        $logP += -log($CharMarkov[$part]->prob(@char, @{$LforChar[$part]}));
        $logP += log($CharUT[$part]) if ($char[1] == $CharIntStr[$part]->int($UT));
        shift(@char);
    }

    return($logP);

#    return($logP+log($UKprob[$part]));
}


#-------------------------------------------------------------------------------------
#                        MorpIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ��ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub MorpIntStr{
    warn "main::MorpIntStr\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){
            ($.%$STEP == 0) || next;
            grep($hash{$_} = 0, split);
        }
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", @Tokens, grep($HASH{$_} >= $MIN, sort(keys(%HASH)))), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        MorpMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ������ǥ�٥�Υޥ륳�ե�ǥ����������

sub MorpMarkov{
    warn "main::MorpMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @stat = map($MorpIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat));
        }
        close(CORPUS);
    }
    foreach (@Part){                              # F(UT) > 0 ���ݾڤ��� (floaring)
        $markov->inc(($MorpIntStr->int($_)) x ($MO+1));
    }
}


#-------------------------------------------------------------------------------------
#                        CalcMorpLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ������ǥ�٥�Υޥ륳�ե�ǥ����������

sub CalcMorpLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե�ǥ�μ���
    my($LAMBDA) = shift;                          # ��ַ����Υե�����̾

    my(@MorpMarkov);                              # �����Х�ǡ�������ѤΥ�ǥ�

    foreach $n (@Kcross){                         # �������ѤΥޥ륳�ե�ǥ������
        $MorpMarkov[$n] = new MarkovHashMemo($MorpIntStr->size);
#        $FILE = sprintf("MorpMarkov%02d", $n);
#        $MorpMarkov[$n] = new MarkovHashDisk($MorpIntStr->size, $FILE);
        &MorpMarkov($MorpMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $MorpMarkov[$n]->test($MorpIntStr, @MorpMarkovTest);
#        $MorpMarkov[$n]->put(sprintf("MorpMarkov%02d", $n));
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
            my(@stat) = map($MorpIntStr->int($_), (($BT) x $MO, split, $BT));
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
        @LforMorp = @Lnew;                    # �����ȥ�å���
        @Lnew = (0) x @LforMorp;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $MorpMarkov[$n]->OneIteration($Tran[$n], @LforMorp);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforMorp));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforMorp));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforMorp));

    undef(@MorpMarkov);

    my($FILE) = "> $LAMBDA";                          # ��ַ����ե����������
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforMorp)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        CharIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ʸ���ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub CharIntStr{
    warn "main::CharIntStr\n";
    my($FILE, $part) = (shift, shift);

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $morp (split){                # ������ñ�̤Υ롼��
                ($MorpIntStr->str($MorpIntStr->int($morp)) eq $Part[$part]) || next;
                grep($hash{$_} = 0, &Morphs2Chars($morp));
            }
        }
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, $BT, grep($HASH{$_} >= $MIN, sort(keys(%HASH)))), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        CharMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ʸ�� bigram ���������롣

sub CharMarkov{
    warn "main::CharMarkov\n";
    my($markov, $intstr, $part) = (shift, shift, shift);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $morp (split){                # ������ñ�̤Υ롼��
                ($MorpIntStr->str($MorpIntStr->int($morp)) eq $Part[$part]) || next;
                @stat = map($intstr->int($_), ($BT, &Morphs2Chars($morp), $BT));
                grep(! $markov->inc(@stat[$_-1, $_]), (1 .. $#stat));
            }
        }
        close(CORPUS);
    }
    $markov->inc(($intstr->int($UT)) x 2);        # F(UT) > 0 ���ݾڤ��� (floaring)
    $markov->inc(($intstr->int($BT)) x 2);        # F(BT) > 0 ���ݾڤ��� (floaring)
}


#=====================================================================================
#                        END
#=====================================================================================
