use bytes;
#=====================================================================================
#                        CrossEntropyByDepend.perl
#                             by Shinsuke Mori
#                             Last change : 14 May 2008
#=====================================================================================

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

# 機  能 : 引数で与えられるコーパスを読み込み、を生成する。
#
# 注  意 : 後ろから順に予測する。

sub Dist{
    warn "main::Dist\n";
    my($dist) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # 文単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、単語と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

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
        while (<CORPUS>){                         # 文単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、単語レベルのマルコフモデルを生成する。
#
# 注  意 : 後ろから順に予測する。

sub MorpMarkov{
    warn "main::MorpMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        my($IRS) = CORPUS->input_record_separator("\n\n");
        while (<CORPUS>){                         # 文単位のループ
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
            foreach $morp (map((new Morpheme(split))->morp, split("\n"))){
                ($MorpIntStr->int($morp) == $MorpIntStr->int($Part[$part])) || next;
                @state = map($intstr->int($_), ($BT, &Morphs2Chars($morp), $BT));
                grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
            }
        }
        CORPUS->input_record_separator($IRS);
        close(CORPUS);
    }
    $markov->inc(($intstr->int($UT)) x 2);        # F(UT) > 0 を保証する (floaring)
    $markov->inc(($intstr->int($BT)) x 2);        # F(BT) > 0 を保証する (floaring)
}


#=====================================================================================
#                        END
#=====================================================================================
