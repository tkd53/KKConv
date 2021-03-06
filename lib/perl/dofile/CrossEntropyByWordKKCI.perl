use bytes;
#=====================================================================================
#                       CrossEntropyByWordKKCI.perl
#                             bShinsuke Mori
#                             Last change 17 September 2012
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        Corpus Template
#-------------------------------------------------------------------------------------

$CTEMPL = "$TKD53HOME/corpus/%02d.wordkkci";           # コーパスのファイル名の生成の雛型


#-------------------------------------------------------------------------------------
#                        Line2Units
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、文字のリストを返す。
#
# 注  意 : 文は "表記/入力記号列 ..." となっている必要がある。

sub Line2Units{
    return(split(" ", shift));
}


#-------------------------------------------------------------------------------------
#                        Line2Chars
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、文字のリストを返す。
#
# 注  意 : 文は "表記/入力記号列 ..." となっている必要がある。

sub Line2Chars{
    return(map(m/(..)/g, map((split("/"))[0], split(" ", shift))));
}


#-------------------------------------------------------------------------------------
#                        UWlogP
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる形態素の文字列の対数確率を返す。
#
# 注  意 : グローバル変数($BT, $CharIntStr, $LforChar, $CharMarkov)を仮定している。

sub UWlogP{
    my($word) = shift;

    my($logP) = 0;
    my(@char) = ($CharIntStr->int($BT)) x 1;
    foreach (($word =~ m/(..)/g), $BT){           # 文字単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、単語と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

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

# 機  能 : 引数で与えられるコーパスを読み込み、単語レベルのマルコフモデルを生成する。

sub WordMarkov{
    warn "main::WordMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
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

# 機  能 : 補間係数の推定

sub CalcWordLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # マルコフモデルの次数
    my($LAMBDA) = shift;                          # 補間係数のファイル名

    my(@WordMarkov);                              # クロスバリデーション用のモデル
    foreach $n (@Kcross){                         # 削除補間用のマルコフモデルの生成
#    foreach $n (1,2,3){                           # 削除補間用のマルコフモデルの生成
#    foreach $n (4,5,6){                           # 削除補間用のマルコフモデルの生成
#    foreach $n (7,8,9){                           # 削除補間用のマルコフモデルの生成
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

    my(@Tran);                                    # [(状態列, 頻度)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack の TEMPLATE
    foreach $n (@Kcross){                         # コーパスをメモリに読み込む
        $FILE = sprintf($CTEMPL, $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){                           # 文単位のループ
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

    my($TEMPLATE) = "%6.4f";                      # 補間係数の比較桁数
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EMアルゴリズムの初期値
#    @Lnew = (0.0049, 0.9951);
    do {                                          # EMアルゴリズムのループ
        @LforWord = @Lnew;                        # 少々トリッキー
        @Lnew = (0) x @LforWord;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $WordMarkov[$n]->OneIteration($Tran[$n], @LforWord);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#Lnew));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#Lnew));
        printf(STDERR "λ = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforWord));

    undef(@WordMarkov);

    my($FILE) = "> $LAMBDA";                      # 補間係数ファイルの生成
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforWord)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        CharIntStr
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、文字と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスに現れる文字を対象とする。

sub CharIntStr{
    warn "main::CharIntStr\n";
    my($FILE) = shift;

    my(%HASH, %hash);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        %hash = ();
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){      # 単語単位のループ
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                $word = (split("/", $unit))[0];
                $word =~ s/\=//g;                 # for 連語
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

# 機  能 : 引数で与えられるコーパスを読み込み、文字 bigram を生成する。

sub CharMarkov{
    warn "main::CharMarkov\n";
    my($markov) = shift;

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){    # 単語単位のループ
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                $word = (split("/", $unit))[0];
                $word =~ s/\=//g;                 # for 連語
                @state = map($CharIntStr->int($_), ($BT, ($word =~ m/(..)/g), $BT));
                grep(! $markov->inc(@state[$_-1, $_]), (1..$#state));
            }
        }
        close(CORPUS);
    }
    $markov->inc(($CharIntStr->int($UT)) x 2);    # F(UT) > 0 を保証する (floaring)
    $markov->inc(($CharIntStr->int($BT)) x 2);    # F(BT) > 0 を保証する (floaring)
}


#-------------------------------------------------------------------------------------
#                        CalcCharLambda
#-------------------------------------------------------------------------------------

# 機  能 : 補間係数の推定

sub CalcCharLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # マルコフモデルの次数
    my($LAMBDA) = shift;                          # 補間係数のファイル名

    my(@CharMarkov);                              # クロスバリデーション用のモデル
    foreach $n (@Kcross){                         # 削除補間用のマルコフモデルの生成
        $CharMarkov[$n] = new MarkovHashMemo($CharIntStr->size);
        &CharMarkov($CharMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $CharMarkov[$n]->test($CharIntStr, @CharMarkovTest);
        warn "\n";
    }

    my(@Tran);                                    # [(状態列, 頻度)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack の TEMPLATE
    foreach $n (@Kcross){                         # コーパスをメモリに読み込む
        $FILE = sprintf($CTEMPL, $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){                           # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $unit (&Line2Units($_)){      # 単語単位のループ
                next unless ($WordIntStr->int($unit) == $WordIntStr->int($UT));
                $word = (split("/", $unit))[0];
                $word =~ s/\=//g;                 # for 連語
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

    my($TEMPLATE) = "%6.4f";                      # 補間係数の比較桁数
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EMアルゴリズムの初期値
    do {                                          # EMアルゴリズムのループ
        @LforChar = @Lnew;                        # 少々トリッキー
        @Lnew = (0) x @Lnew;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            @Ltmp = $CharMarkov[$n]->OneIteration($Tran[$n], @LforChar);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#Lnew));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#Lnew));
        printf(STDERR "λ = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforChar));

    undef(@CharMarkov);

    my($FILE) = "> $LAMBDA";                      # 補間係数ファイルの生成
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforChar)), "\n";
    close(FILE);
}


#=====================================================================================
#                        END
#=====================================================================================
