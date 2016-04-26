use bytes;
#=====================================================================================
#                       CrossEntropyByMorp.perl
#                             bShinsuke Mori
#                             Last change 6 June 2010
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        Line2Units
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、文字のリストを返す。
#
# 注  意 : 文は "表記/????..." となっている必要がある。

sub Line2Units{
    return(split(" ", shift));
}


#-------------------------------------------------------------------------------------
#                        Line2Chars
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、文字のリストを返す。
#
# 注  意 : 文は "表記/????..." となっている必要がある。

sub Line2Chars{
    return(map(m/(..)/g, map((split("/"))[0], split(" ", shift))));
}


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

#    return($logP+log($UKprob[$part]));
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

# 機  能 : 引数で与えられるコーパスを読み込み、形態素レベルのマルコフモデルを生成する

sub MorpMarkov{
    warn "main::MorpMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            @stat = map($MorpIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat));
        }
        close(CORPUS);
    }
    foreach (@Part){                              # F(UT) > 0 を保証する (floaring)
        $markov->inc(($MorpIntStr->int($_)) x ($MO+1));
    }
}


#-------------------------------------------------------------------------------------
#                        CalcMorpLambda
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、形態素レベルのマルコフモデルを生成する

sub CalcMorpLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # マルコフモデルの次数
    my($LAMBDA) = shift;                          # 補間係数のファイル名

    my(@MorpMarkov);                              # クロスバリデーション用のモデル

    foreach $n (@Kcross){                         # 削除補間用のマルコフモデルの生成
        $MorpMarkov[$n] = new MarkovHashMemo($MorpIntStr->size);
#        $FILE = sprintf("MorpMarkov%02d", $n);
#        $MorpMarkov[$n] = new MarkovHashDisk($MorpIntStr->size, $FILE);
        &MorpMarkov($MorpMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $MorpMarkov[$n]->test($MorpIntStr, @MorpMarkovTest);
#        $MorpMarkov[$n]->put(sprintf("MorpMarkov%02d", $n));
        warn "\n";
    }

    my(@Tran);                                    # [(状態列, 頻度)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack の TEMPLATE
    foreach $n (@Kcross){                         # コーパスをメモリに読み込む
        my($FILE) = sprintf($CTEMPL, $n);
        open(FILE, $FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        my(%Tran);                                # 状態列 => 頻度
        while (<FILE>){
            ($.%$STEP == 0) || next;
            my(@stat) = map($MorpIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $Tran{pack($PT, @stat[$_-$MO .. $_])}++, ($MO .. $#stat));
        }
        close(FILE);

        $Tran[$n] = [];                           # (状態列, 頻度)+
        while (($key, $val) = each(%Tran)){
            push(@{$Tran[$n]}, [unpack($PT, $key), $val]);
        }
        undef(%Tran);
    }

    my($TEMPLATE) = "%6.4f";                      # 補間係数の比較桁数
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EMアルゴリズムの初期値
    do {                                          # EMアルゴリズムのループ
        @LforMorp = @Lnew;                    # 少々トリッキー
        @Lnew = (0) x @LforMorp;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $MorpMarkov[$n]->OneIteration($Tran[$n], @LforMorp);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforMorp));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforMorp));
        printf(STDERR "λ = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforMorp));

    undef(@MorpMarkov);

    my($FILE) = "> $LAMBDA";                          # 補間係数ファイルの生成
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforMorp)), "\n";
    close(FILE);
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
        %hash = ();
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $morp (split){                # 形態素単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、文字 bigram を生成する。

sub CharMarkov{
    warn "main::CharMarkov\n";
    my($markov, $intstr, $part) = (shift, shift, shift);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $morp (split){                # 形態素単位のループ
                ($MorpIntStr->str($MorpIntStr->int($morp)) eq $Part[$part]) || next;
                @stat = map($intstr->int($_), ($BT, &Morphs2Chars($morp), $BT));
                grep(! $markov->inc(@stat[$_-1, $_]), (1 .. $#stat));
            }
        }
        close(CORPUS);
    }
    $markov->inc(($intstr->int($UT)) x 2);        # F(UT) > 0 を保証する (floaring)
    $markov->inc(($intstr->int($BT)) x 2);        # F(BT) > 0 を保証する (floaring)
}


#=====================================================================================
#                        END
#=====================================================================================
