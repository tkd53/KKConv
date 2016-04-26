use bytes;
#=====================================================================================
#                        CrossEntropyBySCFG.perl
#                             by Shinsuke Mori
#                             Last change : 14 May 2008
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

# $CTEMPL は CrossEntropyBy.perl の定義を上書きする。

$CTEMPL = "../../../corpus/NKN%02d.depend";          # コーパスのファイル名の生成の雛型

@Cont = ("名詞", "動詞", "形容動詞", "数字", "副詞", "形容詞", "連体詞", "接続詞",
         "記号", "感動詞", "接頭語","接尾語");
@Func = ("NULL", "助詞", "助動詞", "語尾");
@Sign = ("NULL", "句点", "読点");

%Cont = map(($_ => 1), @Cont);
%Func = map(($_ => 1), @Func);

$Sent = "Sent";                                   # 開始記号


#-------------------------------------------------------------------------------------
#                        UMlogP
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる形態素の文字列の対数確率を返す。
#
# 注  意 : グローバル変数($BT, $CharIntStr, $LforChar, $CharMarkov)を仮定している。

sub UMlogP{
    my($morp) = shift;

    my($part) = $Part{(split("/", $morp))[1]};

    my($logP) = 0;
    my(@char) = ($CharIntStr[$part]->int($BT)) x 1;
    foreach (&Morphs2Chars($morp), $BT){          # 文字単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、単語と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

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
        while (<CORPUS>){                         # 文単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、単語と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

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
        while (<CORPUS>){                         # 文単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、単語レベルのマルコフモデルを生成する。
#
# 注  意 : 後ろから順に予測する。

sub ContMarkov{
    warn "main::ContMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
#                ($bunsetsu->cont > 0) || next;    # 恒真
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
        $markov->inc(($ContIntStr->int($_)) x 2); # F(UT) > 0 を保証する (floaring)
    }
}


#-------------------------------------------------------------------------------------
#                        FuncMarkov
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、単語レベルのマルコフモデルを生成する。
#
# 注  意 : 後ろから順に予測する。

sub FuncMarkov{
    warn "main::FuncMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # 文単位のループ
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
        $markov->inc(($FuncIntStr->int($_)) x 2); # F(UT) > 0 を保証する (floaring)
    }
}


#-------------------------------------------------------------------------------------
#                        CharIntStr
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、文字と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

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
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                foreach $morp ($bunsetsu->cont){  # 形態素単位のループ
                    next unless ($ContIntStr->int($morp) == $ContIntStr->int($UT));
                    next unless ((split("/", $morp))[1] eq $Part[$part]);
                    grep($hash{$_} = 0, &Morphs2Chars($morp));
                }
                foreach $morp ($bunsetsu->func){  # 形態素単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、文字 bigram を生成する。

sub CharMarkov{
    warn "main::CharMarkov\n";
    my($markov, $intstr, $part) = (shift, shift, shift);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                foreach $morp ($bunsetsu->cont){  # 形態素単位のループ
                    next unless ($ContIntStr->int($morp) == $ContIntStr->int($UT));
                    next unless ((split("/", $morp))[1] eq $Part[$part]);
                    @state = map($intstr->int($_), ($BT, &Morphs2Chars($morp), $BT));
                    grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
                }
                foreach $morp ($bunsetsu->func){  # 形態素単位のループ
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
    $markov->inc(($intstr->int($UT)) x 2);        # F(UT) > 0 を保証する (floaring)
    $markov->inc(($intstr->int($BT)) x 2);        # F(BT) > 0 を保証する (floaring)
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
        while (<CORPUS>){                         # 文単位のループ
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
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $bunsetsu (map(new Bunsetsu(split), split("\n"))){
                ($bunsetsu->sign == 1) && $SignFreq{($bunsetsu->sign)[0]}++;
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }

    $SignProb{"、/記号"} = $SignFreq{"、/記号"}
                          /($SignFreq{"、/記号"}+$SignFreq{"，/記号"});
    $SignProb{"，/記号"} = $SignFreq{"，/記号"}
                          /($SignFreq{"、/記号"}+$SignFreq{"，/記号"});
    $SignProb{"。/記号"} = $SignFreq{"。/記号"}
                          /($SignFreq{"。/記号"}+$SignFreq{"．/記号"});
    $SignProb{"．/記号"} = $SignFreq{"．/記号"}
                          /($SignFreq{"。/記号"}+$SignFreq{"．/記号"});

    printf(FILE "\$SignProb{\"、/記号\"} = %6.4f;\n", $SignProb{"、/記号"});
    printf(FILE "\$SignProb{\"，/記号\"} = %6.4f;\n", $SignProb{"，/記号"});
    printf(FILE "\$SignProb{\"。/記号\"} = %6.4f;\n", $SignProb{"。/記号"});
    printf(FILE "\$SignProb{\"．/記号\"} = %6.4f;\n", $SignProb{"．/記号"});
    print FILE "\n";

    close(FILE);
}


#=====================================================================================
#                        END
#=====================================================================================
