#=====================================================================================
#                       CrossEntropyByClst.perl
#                             bShinsuke Mori
#                             Last change 22 July 2010
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        ClstMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ������ǥ�٥�Υޥ륳�ե�ǥ����������

sub ClstMarkov{
    warn "main::ClstMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @stat = map($ClstIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
#            print STDERR join(" ", map($ClstIntStr->str($_), @stat)), "\n";
#            exit(0);
#            @stat = map($ClstIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat)); 
        }
        close(CORPUS);
    }
    foreach (@Part){                              # F(UT) > 0 ���ݾڤ��� (floaring)
        $markov->inc(($ClstIntStr->int($_)) x ($MO+1));
    }
}


#-------------------------------------------------------------------------------------
#                        CalcClstLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ������ǥ�٥�Υޥ륳�ե�ǥ����������

sub CalcClstLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե�ǥ�μ���
    my($LAMBDA) = shift;                          # ��ַ����Υե�����̾

    my(@ClstMarkov);                              # �����Х�ǡ�������ѤΥ�ǥ�

    foreach $n (@Kcross){                         # �������ѤΥޥ륳�ե�ǥ������
        $ClstMarkov[$n] = new MarkovHashMemo($ClstIntStr->size);
#        $FILE = sprintf("ClstMarkov%02d", $n);
#        $ClstMarkov[$n] = new MarkovHashDisk($ClstIntStr->size, $FILE);
        &ClstMarkov($ClstMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $ClstMarkov[$n]->test($ClstIntStr, @ClstMarkovTest);
#        $ClstMarkov[$n]->put(sprintf("ClstMarkov%02d", $n));
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
            my(@stat) = map($ClstIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
#            my(@stat) = map($ClstIntStr->int($_), (($BT) x $MO, split, $BT));
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
        @LforClst = @Lnew;                    # �����ȥ�å���
        @Lnew = (0) x @LforClst;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $ClstMarkov[$n]->OneIteration($Tran[$n], @LforClst);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforClst));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforClst));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforClst));
    
    undef(@ClstMarkov);

    my($FILE) = "> $LAMBDA";                          # ��ַ����ե����������
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforClst)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        ñ�� 2-gram ��ǥ���ɤ߹���
#-------------------------------------------------------------------------------------

# ClstRead2gramModel(STRING)
#
# ��  ǽ : STRING ����Ƭ���Ȥ���ե����뤫�� 2-gram ��ǥ���ɤ߹��ࡣ
#
# ��  �� : ($ClstIntStr, $ClstMarkov, @LforClst) = &ClstRead2gramModel("Clst");
#
# ����� : 

sub ClstRead2gramModel{
    (@_ == 2) || die;
    my($prefix, $FILE) = (shift, shift);

    printf(STDERR "Reading %sIntStr.text, %sMarkov.db, and %sLambda ... ",
           ($prefix) x 3);

    my($IntStr) = new WordClstIntStr($prefix . "IntStr.text", $FILE);

    my($Markov) = new MarkovHashDisk($IntStr->size, $prefix . "Markov");

    $LAMBDA = $prefix . "Lambda";
    open(LAMBDA, $LAMBDA) || die "Can't open $LAMBDA: $!\n";
    my(@Lambda) = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
    close(LAMBDA);

    warn "Done\n";

    return($IntStr, $Markov, @Lambda);
}


#=====================================================================================
#                        END
#=====================================================================================
