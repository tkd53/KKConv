#=====================================================================================
#                       CrossEntropyByWordKKCI.perl
#                             bShinsuke Mori
#                             Last change 17 September 2012
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        Corpus Template
#-------------------------------------------------------------------------------------

$CTEMPL = "$TKD53HOME/corpus/%02d.wordkkci";           # �����ѥ��Υե�����̾�������ο���


#-------------------------------------------------------------------------------------
#                        Line2Units
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ������ʸ���ɤ߹��ߡ�ʸ���Υꥹ�Ȥ��֤���
#
# ��  �� : ʸ�� "ɽ��/���ϵ����� ..." �ȤʤäƤ���ɬ�פ����롣

sub Line2Units{
    return(split(" ", shift));
}


#-------------------------------------------------------------------------------------
#                        Line2Chars
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ������ʸ���ɤ߹��ߡ�ʸ���Υꥹ�Ȥ��֤���
#
# ��  �� : ʸ�� "ɽ��/���ϵ����� ..." �ȤʤäƤ���ɬ�פ����롣

sub Line2Chars{
    return(map(m/(..)/g, map((split("/"))[0], split(" ", shift))));
}


#-------------------------------------------------------------------------------------
#                        UWlogP
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ����������Ǥ�ʸ������п���Ψ���֤���
#
# ��  �� : �����Х��ѿ�($BT, $CharIntStr, $LforChar, $CharMarkov)���ꤷ�Ƥ��롣

sub UWlogP{
    my($word) = shift;

    my($logP) = 0;
    my(@char) = ($CharIntStr->int($BT)) x 1;
    foreach (($word =~ m/(..)/g), $BT){           # ʸ��ñ�̤Υ롼��
        push(@char, $CharIntStr->int($_));
        $logP += -log($CharMarkov->prob(@char, @LforChar));
        $logP += log($CharUT) if ($char[1] == $CharIntStr->int($UT));
        shift(@char);
    }

    return($logP);
}


#-------------------------------------------------------------------------------------
#                        WordIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ��ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub WordIntStr{
    warn "main::WordIntStr\n";
    my($FILE) = shift;

    my(%FREQ, %HASH, %flag);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %flag = ();
        while (<CORPUS>){
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){
                $flag{$unit} = 1;
#                $FREQ{$unit}++;
            }
        }
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%flag));
    }

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
#    my(@unit) = sort {$FREQ{$b} <=> $FREQ{$a}} grep($HASH{$_} >= $MIN, keys(%FREQ));
#    @unit = @unit[0 .. 999999] if (scalar(@unit) > 1000000);
#    print FILE join("\n", $UT, $BT, sort(@unit)), "\n"; # for a paper
    print FILE join("\n", $UT, $BT, grep($HASH{$_} >= $MIN, sort(keys(%HASH)))), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        WordMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ���٥�Υޥ륳�ե�ǥ���������롣

sub WordMarkov{
    warn "main::WordMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @stat = map($WordIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat));
        }
        close(CORPUS);
    }
}


#-------------------------------------------------------------------------------------
#                        CalcWordLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ��ַ����ο���

sub CalcWordLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե�ǥ�μ���
    my($LAMBDA) = shift;                          # ��ַ����Υե�����̾

    my(@WordMarkov);                              # �����Х�ǡ�������ѤΥ�ǥ�
    foreach $n (@Kcross){                         # �������ѤΥޥ륳�ե�ǥ������
#    foreach $n (1,2,3){                           # �������ѤΥޥ륳�ե�ǥ������
#    foreach $n (4,5,6){                           # �������ѤΥޥ륳�ե�ǥ������
#    foreach $n (7,8,9){                           # �������ѤΥޥ륳�ե�ǥ������
        $FILE = sprintf("WordMarkov%02d", $n);
        if (-r "$FILE.db"){
#            $WordMarkov[$n] = new MarkovHashMemo($WordIntStr->size, $FILE);
            $WordMarkov[$n] = new MarkovHashDisk($WordIntStr->size, $FILE);
        }else{
            $WordMarkov[$n] = new MarkovHashMemo($WordIntStr->size);
            &WordMarkov($WordMarkov[$n],
                        map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
#            $FILE = sprintf("/dev/shm/WordMarkov%02d", $n);
#            $FILE = sprintf("/mnt/RAM/WordMarkov%02d", $n);
#            $WordMarkov[$n]->put($FILE);
#            system("/bin/mv $FILE.db .");
        }
        $WordMarkov[$n]->test($WordIntStr, @WordMarkovTest);
        warn "\n";
    }
#    exit(0);

    my(@Tran);                                    # [(������, ����)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack �� TEMPLATE
    foreach $n (@Kcross){                         # �����ѥ��������ɤ߹���
        $FILE = sprintf($CTEMPL, $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){                           # ʸñ�̤Υ롼��
            ($.% 25 == 0) || next;
#            ($.%$STEP == 0) || next;
            @stat = map($WordIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
            grep(! $Tran{pack($PT, @stat[$_-$MO .. $_])}++, ($MO .. $#stat));
        }
        close(FILE);

        $Tran[$n] = [];
        while (($key, $val) = each(%Tran)){
            push(@{$Tran[$n]}, [unpack($PT, $key), $val]);
        }
        undef(%Tran);
    }

    my($TEMPLATE) = "%6.4f";                      # ��ַ�������ӷ��
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EM���르�ꥺ��ν����
#    @Lnew = (0.0049, 0.9951);
    do {                                          # EM���르�ꥺ��Υ롼��
        @LforWord = @Lnew;                        # �����ȥ�å���
        @Lnew = (0) x @LforWord;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $WordMarkov[$n]->OneIteration($Tran[$n], @LforWord);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#Lnew));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#Lnew));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforWord));

    undef(@WordMarkov);

    my($FILE) = "> $LAMBDA";                      # ��ַ����ե����������
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforWord)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        CharIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ʸ���ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��˸����ʸ�����оݤȤ��롣

sub CharIntStr{
    warn "main::CharIntStr\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){      # ñ��ñ�̤Υ롼��
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                $word = (split("/", $unit))[0];
                $word =~ s/\=//g;                 # for Ϣ��
                grep($hash{$_} = 0, ($word =~ m/(..)/g));
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
    my($markov) = shift;

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){    # ñ��ñ�̤Υ롼��
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                $word = (split("/", $unit))[0];
                $word =~ s/\=//g;                 # for Ϣ��
                @state = map($CharIntStr->int($_), ($BT, ($word =~ m/(..)/g), $BT));
                grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
            }
        }
        close(CORPUS);
    }
    $markov->inc(($CharIntStr->int($UT)) x 2);    # F(UT) > 0 ���ݾڤ��� (floaring)
    $markov->inc(($CharIntStr->int($BT)) x 2);    # F(BT) > 0 ���ݾڤ��� (floaring)
}


#-------------------------------------------------------------------------------------
#                        CalcCharLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ��ַ����ο���

sub CalcCharLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե�ǥ�μ���
    my($LAMBDA) = shift;                          # ��ַ����Υե�����̾

    my(@CharMarkov);                              # �����Х�ǡ�������ѤΥ�ǥ�
    foreach $n (@Kcross){                         # �������ѤΥޥ륳�ե�ǥ������
        $CharMarkov[$n] = new MarkovHashMemo($CharIntStr->size);
        &CharMarkov($CharMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $CharMarkov[$n]->test($CharIntStr, @CharMarkovTest);
        warn "\n";
    }

    my(@Tran);                                    # [(������, ����)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack �� TEMPLATE
    foreach $n (@Kcross){                         # �����ѥ��������ɤ߹���
        $FILE = sprintf($CTEMPL, $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){                           # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){      # ñ��ñ�̤Υ롼��
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                $word = (split("/", $unit))[0];
                $word =~ s/\=//g;                 # for Ϣ��
                @stat = map($CharIntStr->int($_), ($BT, ($word =~ m/(..)/g), $BT));
                grep(! $Tran{pack($PT, @stat[$_-$MO, $_])}++, ($MO .. $#stat));
            }
        }
        close(FILE);

        $Tran[$n] = [];
        while (($key, $val) = each(%Tran)){
            push(@{$Tran[$n]}, [unpack($PT, $key), $val]);
        }
        undef(%Tran);
    }

    my($TEMPLATE) = "%6.4f";                      # ��ַ�������ӷ��
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EM���르�ꥺ��ν����
    do {                                          # EM���르�ꥺ��Υ롼��
        @LforChar = @Lnew;                        # �����ȥ�å���
        @Lnew = (0) x @Lnew;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            @Ltmp = $CharMarkov[$n]->OneIteration($Tran[$n], @LforChar);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#Lnew));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#Lnew));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforChar));

    undef(@CharMarkov);

    my($FILE) = "> $LAMBDA";                      # ��ַ����ե����������
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforChar)), "\n";
    close(FILE);
}


#=====================================================================================
#                        END
#=====================================================================================
