use bytes;
#=====================================================================================
#                        CrossEntropyByDepend.perl
#                             by Shinsuke Mori
#                             Last change : 14 May 2008
#=====================================================================================

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
}


#-------------------------------------------------------------------------------------
#                        Dist
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ����������롣
#
# ��  �� : �������ͽ¬���롣

sub Dist{
    warn "main::Dist\n";
    my($dist) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @morp = map(new Morpheme(split), split("\n"));
            @list = ();
            for ($i = 0; $i < @morp; $i++){
#                printf(STDERR "%2d\n", scalar(grep($_ == $i, @list)));
                $dist->inc(scalar(grep($_ == $i, @list)));
                @list = grep($_ > $i, @list);
                push(@list, $morp[$i]->dest);
            }
            $dist->inc(1);
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }
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
        my($IRS) = CORPUS->input_record_separator("\n\n");
        %hash = ();
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            grep($hash{(new Morpheme(split))->morp} = 0, split("\n"));
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
        grep(! $HASH{$_}++, keys(%hash));
    }

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, $BT, @Part, grep($HASH{$_} >= $MIN, keys(%HASH))),"\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        MorpMarkov
#-------------------------------------------------------------------------------------

# ��  ǽ : ������Ϳ�����륳���ѥ����ɤ߹��ߡ�ñ���٥�Υޥ륳�ե�ǥ���������롣
#
# ��  �� : �������ͽ¬���롣

sub MorpMarkov{
    warn "main::MorpMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # ʸñ�̤Υ롼��
            ($.%$STEP == 0) || next;
            @morp = map(new Morpheme(split), split("\n"));
            for ($i = 0; $i < @morp; $i++){
                @from = grep(($morp[$_]->dest == $i), (0 .. $i-1));
                $Sfol = $MorpIntStr->int($morp[$i]->morp);
                if (@from == 0){
                    $markov->inc($MorpIntStr->int($BT), $Sfol);
                }else{
                    foreach (@from){
                        $markov->inc($MorpIntStr->int($morp[$_]->morp), $Sfol);
                    }
                }
            }
            $markov->inc(map($MorpIntStr->int($_), ($morp[$#morp]->morp, $BT)));
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
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
            foreach $morp (map((new Morpheme(split))->morp, split("\n"))){
                ($MorpIntStr->int($morp) == $MorpIntStr->int($Part[$part])) || next;
                grep($hash{$_} = 0, &Morphs2Chars($morp));
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
            foreach $morp (map((new Morpheme(split))->morp, split("\n"))){
                ($MorpIntStr->int($morp) == $MorpIntStr->int($Part[$part])) || next;
                @state = map($intstr->int($_), ($BT, &Morphs2Chars($morp), $BT));
                grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }
    $markov->inc(($intstr->int($UT)) x 2);        # F(UT) > 0 ���ݾڤ��� (floaring)
    $markov->inc(($intstr->int($BT)) x 2);        # F(BT) > 0 ���ݾڤ��� (floaring)
}


#=====================================================================================
#                        END
#=====================================================================================
