use bytes;
#=====================================================================================
#                        CrossEntropyBySCFG.perl
#                             by Shinsuke Mori
#                             Last change : 14 May 2008
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

# $CTEMPL �� CrossEntropyBy.perl ��������񤭤��롣

$CTEMPL = "../../../corpus/NKN%02d.depend";          # �����ѥ��Υե�����̾�������ο���

@Cont = ("̾��", "ư��", "����ư��", "����", "����", "���ƻ�", "Ϣ�λ�", "��³��",
         "����", "��ư��", "��Ƭ��","������");
@Func = ("NULL", "����", "��ư��", "����");
@Sign = ("NULL", "����", "����");

%Cont = map(($_ => 1), @Cont);
%Func = map(($_ => 1), @Func);

$Sent = "Sent";                                   # ���ϵ���


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
#        printf(STDERR "int(%s) = %d\n", $_, $CharIntStr[$part]->int($_));
        push(@char, $CharIntStr[$part]->int($_));
        $logP += -log($CharMarkov[$part]->prob(@char, @{$LforChar[$part]}));
#        printf(STDERR "INT(%s) = %d\n", $_, $CharIntStr[$part]->int($_));
        $logP += log($CharUT[$part]) if ($char[1] == $CharIntStr[$part]->int($UT));
        shift(@char);
    }

    return($logP);

#    return($logP+log($UKprob[$part]));
}


#-------------------------------------------------------------------------------------
#                        ContIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ��ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub ContIntStr{
    warn "main::ContIntStr\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        %hash = ();
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                grep($hash{$_} = 0, $bunsetsu->cont);
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, @Part, $BT, grep($HASH{$_} >= $MIN, keys(%HASH))),"\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        FuncIntStr
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ��ȿ������б��ط����������롣
#
# ��  �� : $MIN �ʾ����ʬ�����ѥ��Τ˸����ʸ�����оݤȤ��롣

sub FuncIntStr{
    warn "main::FuncIntStr\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        %hash = ();
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                grep($hash{$_} = 0, $bunsetsu->func);
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, @Part, $BT, grep($HASH{$_} >= $MIN, keys(%HASH))),"\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        ContMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ���٥�Υޥ륳�ե�ǥ���������롣
#
# ��  �� : �������ͽ¬���롣

sub ContMarkov{
    warn "main::ContMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
#                ($bunsetsu->cont > 0) || next;    # ����
                @state = map(($ContIntStr->int($_) ||
                              $ContIntStr->int((split("/"))[1])),
                             reverse($BT, $bunsetsu->cont, $BT));
                grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }
    foreach (@Part){
        $markov->inc(($ContIntStr->int($_)) x 2); # F(UT) > 0 ���ݾڤ��� (floaring)
    }
}


#-------------------------------------------------------------------------------------
#                        FuncMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ���٥�Υޥ륳�ե�ǥ���������롣
#
# ��  �� : �������ͽ¬���롣

sub FuncMarkov{
    warn "main::FuncMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                ($bunsetsu->func > 0) || next;
                @state = map(($FuncIntStr->int($_) ||
                              $FuncIntStr->int((split("/"))[1])),
                             reverse($BT, $bunsetsu->func, $BT));
                grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }
    foreach (@Part){
        $markov->inc(($FuncIntStr->int($_)) x 2); # F(UT) > 0 ���ݾڤ��� (floaring)
    }
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
        my($IRS) = CORPUS->input_record_separator("\n\n");
        %hash = ();
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                foreach $morp ($bunsetsu->cont){  # ������ñ�̤Υ롼��
                    next unless ($ContIntStr->int($morp) == $ContIntStr->int($UT));
                    next unless ((split("/", $morp))[1] eq $Part[$part]);
                    grep($hash{$_} = 0, &Morphs2Chars($morp));
                }
                foreach $morp ($bunsetsu->func){  # ������ñ�̤Υ롼��
                    next unless ($FuncIntStr->int($morp) == $FuncIntStr->int($UT));
                    next unless ((split("/", $morp))[1] eq $Part[$part]);
                    grep($hash{$_} = 0, &Morphs2Chars($morp));
                }
            }
        }
        CORPUS->input_record_separator($IRS);
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
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                foreach $morp ($bunsetsu->cont){  # ������ñ�̤Υ롼��
                    next unless ($ContIntStr->int($morp) == $ContIntStr->int($UT));
                    next unless ((split("/", $morp))[1] eq $Part[$part]);
                    @state = map($intstr->int($_), ($BT, &Morphs2Chars($morp), $BT));
                    grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
                }
                foreach $morp ($bunsetsu->func){  # ������ñ�̤Υ롼��
                    next unless ($FuncIntStr->int($morp) == $FuncIntStr->int($UT));
                    next unless ((split("/", $morp))[1] eq $Part[$part]);
                    @state = map($intstr->int($_), ($BT, &Morphs2Chars($morp), $BT));
                    grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
                }
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }
    $markov->inc(($intstr->int($UT)) x 2);        # F(UT) > 0 ���ݾڤ��� (floaring)
    $markov->inc(($intstr->int($BT)) x 2);        # F(BT) > 0 ���ݾڤ��� (floaring)
}


#-------------------------------------------------------------------------------------
#                        PartFreq
#-------------------------------------------------------------------------------------

sub PartFreq{
    warn "main::PartFreq\n";
    my($FILE) = shift;

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        $IRS = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                grep(! $PartFreqCont[$Part{(split("/", $_))[1]}]++, $bunsetsu->cont);
                grep(! $PartFreqFunc[$Part{(split("/", $_))[1]}]++, $bunsetsu->func);
                ($bunsetsu->sign == 1) && $SignFreq{($bunsetsu->sign)[0]}++;
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }

    print FILE "\@PartFreqCont = (\n";
    foreach (@Part){
        printf(FILE "%s %8d, # %s\n", " " x 16, $PartFreqCont[$Part{$_}], $_);
    }
    printf(FILE "%s);\n\n", " " x 16);

    print FILE "\@PartFreqFunc = (\n";
    foreach (@Part){
        printf(FILE "%s %8d, # %s\n", " " x 16, $PartFreqFunc[$Part{$_}], $_);
    }
    printf(FILE "%s);\n\n", " " x 16);

    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        SignProb
#-------------------------------------------------------------------------------------

sub SignProb{
    warn "main::SignProb\n";
    my($FILE) = shift;

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        $IRS = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                ($bunsetsu->sign == 1) && $SignFreq{($bunsetsu->sign)[0]}++;
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }

    $SignProb{"��/����"} = $SignFreq{"��/����"}
                          /($SignFreq{"��/����"}+$SignFreq{"��/����"});
    $SignProb{"��/����"} = $SignFreq{"��/����"}
                          /($SignFreq{"��/����"}+$SignFreq{"��/����"});
    $SignProb{"��/����"} = $SignFreq{"��/����"}
                          /($SignFreq{"��/����"}+$SignFreq{"��/����"});
    $SignProb{"��/����"} = $SignFreq{"��/����"}
                          /($SignFreq{"��/����"}+$SignFreq{"��/����"});

    printf(FILE "\$SignProb{\"��/����\"} = %6.4f;\n", $SignProb{"��/����"});
    printf(FILE "\$SignProb{\"��/����\"} = %6.4f;\n", $SignProb{"��/����"});
    printf(FILE "\$SignProb{\"��/����\"} = %6.4f;\n", $SignProb{"��/����"});
    printf(FILE "\$SignProb{\"��/����\"} = %6.4f;\n", $SignProb{"��/����"});
    print FILE "\n";

    close(FILE);
}


#=====================================================================================
#                        END
#=====================================================================================
