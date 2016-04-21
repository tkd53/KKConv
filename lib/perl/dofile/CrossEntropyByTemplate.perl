#=====================================================================================
#                       CrossEntropyByTemplate.perl
#                             bShinsuke Mori
#                             Last change 8 March 2015
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        Corpus Template
#-------------------------------------------------------------------------------------

$CTEMPL = "../../../corpus/%02d.template";           # �����ѥ��Υե�����̾�������ο���

$TemplateMarkovTest = join("\n",
  "Ʀ��/F �� ���ä���/Sf �� ��/Ac �� �� ��",
  "�ͻ�/F �� ����/Ac �� �� �� Ʀ��/F �� ��/F �� �Τ�/Ac �� �� ��",
  "������/F �� Ǯ/Ac �� �� �� �ͻ�/F �� ��/ư�� �� �� Ʀ��/F �� ��/T �� ����/Ac �� �� �� ������/��³�� ����/F �� ����/Ac �� �Ǥ�������/Af ��" );


#-------------------------------------------------------------------------------------
#                        Line2Units
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ������ʸ����ɤ߹��ߡ��ƥ�ץ졼�ȤΥꥹ�Ȥ��֤���
#
# ��  �� : ʸ�� "ɽ��/���饹 ..." �ȤʤäƤ���ɬ�פ����롣
#          ʸ��� "ʸ\nʸ\n ..." �ȤʤäƤ���ɬ�פ����롣

sub Line2Units{
    my(@line) = split("\n", shift);

    foreach (@line){
        $_ = join(" ", map((split("/"))[-1], split))
    }

    return(@line);
}


#-------------------------------------------------------------------------------------
#                        Line2Chars
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ������ʸ���ɤ߹��ߡ�ʸ���Υꥹ�Ȥ��֤���
#
# ��  �� : ʸ�� "ɽ��/????..." �ȤʤäƤ���ɬ�פ����롣

sub Line2Chars{
    die "Not Implemented\n";
    return(map(m/(..)/g, map((split("/"))[0], split(" ", shift))));
}


#-------------------------------------------------------------------------------------
#                        UWlogP
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ����������Ǥ�ʸ������п���Ψ���֤���
#
# ��  �� : �����Х��ѿ�($BT, $CharIntStr, $LforChar, $CharMarkov)���ꤷ�Ƥ��롣

sub UWlogP{
    die "Not Implemented\n";
    my($word) = shift;

    my($logP) = 0;
    my(@char) = ($CharIntStr->int($BT)) x 1;
    foreach (($word =~ m/(..)/g), $BT){           # ʸ��ñ�̤Υ롼��
#        printf(STDERR "char = %s\n", $_);
        push(@char, $CharIntStr->int($_));
#        printf(STDERR "char = (%s, %s)\n", @char);
        $logP += -log($CharMarkov->prob(@char, @LforChar));
#        warn "OK\n";
        $logP += log($CharUT) if ($char[1] == $CharIntStr->int($UT));
        shift(@char);
    }

#    printf(STDERR "UWlogP(%s) = %f\n", $word, $logP);
    return($logP);
}


#-------------------------------------------------------------------------------------
#                        TemplateIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ��ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub TemplateIntStr{
    warn "main::TemplateIntStr\n";
    my($FILE) = shift;

    my(%HASH) = ();

    my($TEMP) = $INPUT_RECORD_SEPARATOR;
    $INPUT_RECORD_SEPARATOR = "\n\n";

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my(%hash) = ();
        while (<CORPUS>){
            ($.%$STEP == 0) || next;
#            print STDERR "[", join("]\n[", &Line2Units($_)), "]\n";
#            exit(0);
            grep($hash{$_} = 0, &Line2Units($_));
        }
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }
    $INPUT_RECORD_SEPARATOR = $TEMP;

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, $BT, grep($HASH{$_} >= $MIN, sort(keys(%HASH)))), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        TemplateMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ���٥�Υޥ륳�ե�ǥ���������롣

sub TemplateMarkov{
    warn "main::TemplateMarkov\n";
    my($markov) = shift(@_);

    my($TEMP) = $INPUT_RECORD_SEPARATOR;
    $INPUT_RECORD_SEPARATOR = "\n\n";

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @stat = map($TemplateIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat));
        }
        close(CORPUS);
    }

    $INPUT_RECORD_SEPARATOR = $TEMP;
}


#-------------------------------------------------------------------------------------
#                        CalcTemplateLambda
#-------------------------------------------------------------------------------------

# ��  ǽ : ��ַ����ο���

sub CalcTemplateLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # �ޥ륳�ե�ǥ�μ���
    my($LAMBDA) = shift;                          # ��ַ����Υե�����̾

    my($TEMP) = $INPUT_RECORD_SEPARATOR;
    $INPUT_RECORD_SEPARATOR = "\n\n";

    my(@TemplateMarkov);                          # �����Х�ǡ�������ѤΥ�ǥ�
    foreach $n (@Kcross){                         # �������ѤΥޥ륳�ե�ǥ������
#    foreach $n (1,2,3){                         # �������ѤΥޥ륳�ե�ǥ������
#    foreach $n (4,5,6){                         # �������ѤΥޥ륳�ե�ǥ������
#    foreach $n (7,8,9){                         # �������ѤΥޥ륳�ե�ǥ������
#    foreach $n (9){                         # �������ѤΥޥ륳�ե�ǥ������
        $FILE = sprintf("TemplateMarkov%02d", $n);
#        $FILE = sprintf("/RAM/TemplateMarkov%02d", $n);
#        $FILE = sprintf("/RAM/S/TemplateMarkov%02d", $n);
        if (-r "$FILE.db"){
#            $TemplateMarkov[$n] = new MarkovHashMemo($TemplateIntStr->size, $FILE);
            $TemplateMarkov[$n] = new MarkovHashDisk($TemplateIntStr->size, $FILE);
        }else{
            $TemplateMarkov[$n] = new MarkovHashMemo($TemplateIntStr->size);
#            $TemplateMarkov[$n] = new MarkovHashDisk($TemplateIntStr->size, $FILE);
            &TemplateMarkov($TemplateMarkov[$n],
                        map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
#            $FILE = sprintf("/dev/shm/TemplateMarkov%02d", $n);
#            $TemplateMarkov[$n]->put($FILE);
#            system("/bin/mv $FILE.db .");
        }
#        printf(STDERR "Freq(%s) = %d\n", $BT, $TemplateMarkov[$n]->_1gram(1));
        $TemplateMarkov[$n]->test($TemplateIntStr, @TemplateMarkovTest);
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
            ($.%$STEP == 0) || next;
            @stat = map($TemplateIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
            grep(! $Tran{pack($PT, @stat[$_-$MO .. $_])}++, ($MO .. $#stat));
        }
        close(FILE);

        $Tran[$n] = [];
        while (($key, $val) = each(%Tran)){
            push(@{$Tran[$n]}, [unpack($PT, $key), $val]);
        }
        undef(%Tran);
    }

    $INPUT_RECORD_SEPARATOR = $TEMP;

    my($TEMPLATE) = "%6.4f";                      # ��ַ�������ӷ��
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EM���르�ꥺ��ν����
    do {                                          # EM���르�ꥺ��Υ롼��
        @LforTemplate = @Lnew;                        # �����ȥ�å���
        @Lnew = (0) x @LforTemplate;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $TemplateMarkov[$n]->OneIteration($Tran[$n], @LforTemplate);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#Lnew));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#Lnew));
        printf(STDERR "�� = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforTemplate));

    undef(@TemplateMarkov);

    my($FILE) = "> $LAMBDA";                      # ��ַ����ե����������
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforTemplate)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        CharIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ʸ���ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��˸����ʸ�����оݤȤ��롣

sub CharIntStr{
    die "Not Implemented\n";
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
            foreach $word (&Line2Units($_)){    # ñ��ñ�̤Υ롼��
                next unless ($TemplateIntStr->int($word) == $TemplateIntStr->int($UT));
#                next if ($TemplateMarkov->_1gram($TemplateIntStr->int($word)) > 1); # char
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
    die "Not Implemented\n";
    warn "main::CharMarkov\n";
    my($markov) = shift;

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $word (&Line2Units($_)){    # ñ��ñ�̤Υ롼��
                next unless ($TemplateIntStr->int($word) == $TemplateIntStr->int($UT));
#                next if ($TemplateMarkov->_1gram($TemplateIntStr->int($word)) > 1); # new
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
    die "Not Implemented\n";
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
            foreach $word (&Line2Units($_)){      # ñ��ñ�̤Υ롼��
                next unless ($TemplateIntStr->int($word) == $TemplateIntStr->int($UT));
#                next if ($TemplateMarkov->_1gram($TemplateIntStr->int($word)) > 1); # new
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
