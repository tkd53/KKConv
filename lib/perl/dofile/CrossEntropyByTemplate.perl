#=====================================================================================
#                       CrossEntropyByTemplate.perl
#                             bShinsuke Mori
#                             Last change 8 March 2015
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        Corpus Template
#-------------------------------------------------------------------------------------

$CTEMPL = "../../../corpus/%02d.template";           # コーパスのファイル名の生成の雛型

$TemplateMarkovTest = join("\n",
  "豆腐/F は 冷やっこ用/Sf に し/Ac ま す 。",
  "人参/F を おろ/Ac し て 、 豆腐/F の 上/F に のせ/Ac ま す 。",
  "ごま油/F を 熱/Ac し て 、 人参/F が の/動詞 っ た 豆腐/F の 上/T に かけ/Ac ま す 。 そして/接続詞 醤油/F を かけ/Ac て できあがり/Af 。" );


#-------------------------------------------------------------------------------------
#                        Line2Units
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文列を読み込み、テンプレートのリストを返す。
#
# 注  意 : 文は "表記/クラス ..." となっている必要がある。
#          文列は "文\n文\n ..." となっている必要がある。

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

# 機  能 : 引数で与えられる文を読み込み、文字のリストを返す。
#
# 注  意 : 文は "表記/????..." となっている必要がある。

sub Line2Chars{
    die "Not Implemented\n";
    return(map(m/(..)/g, map((split("/"))[0], split(" ", shift))));
}


#-------------------------------------------------------------------------------------
#                        UWlogP
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる形態素の文字列の対数確率を返す。
#
# 注  意 : グローバル変数($BT, $CharIntStr, $LforChar, $CharMarkov)を仮定している。

sub UWlogP{
    die "Not Implemented\n";
    my($word) = shift;

    my($logP) = 0;
    my(@char) = ($CharIntStr->int($BT)) x 1;
    foreach (($word =~ m/(..)/g), $BT){           # 文字単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、単語と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

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

# 機  能 : 引数で与えられるコーパスを読み込み、単語レベルのマルコフモデルを生成する。

sub TemplateMarkov{
    warn "main::TemplateMarkov\n";
    my($markov) = shift(@_);

    my($TEMP) = $INPUT_RECORD_SEPARATOR;
    $INPUT_RECORD_SEPARATOR = "\n\n";

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
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

# 機  能 : 補間係数の推定

sub CalcTemplateLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # マルコフモデルの次数
    my($LAMBDA) = shift;                          # 補間係数のファイル名

    my($TEMP) = $INPUT_RECORD_SEPARATOR;
    $INPUT_RECORD_SEPARATOR = "\n\n";

    my(@TemplateMarkov);                          # クロスバリデーション用のモデル
    foreach $n (@Kcross){                         # 削除補間用のマルコフモデルの生成
#    foreach $n (1,2,3){                         # 削除補間用のマルコフモデルの生成
#    foreach $n (4,5,6){                         # 削除補間用のマルコフモデルの生成
#    foreach $n (7,8,9){                         # 削除補間用のマルコフモデルの生成
#    foreach $n (9){                         # 削除補間用のマルコフモデルの生成
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

    my(@Tran);                                    # [(状態列, 頻度)+]+
    my($PT) = "I" x ($MO+1);                      # pack, unpack の TEMPLATE
    foreach $n (@Kcross){                         # コーパスをメモリに読み込む
        $FILE = sprintf($CTEMPL, $n);
        open(FILE) || die "Can't open $FILE: $!\n";
        warn "Reading $FILE in Memory\n";
        while (<FILE>){                           # 文単位のループ
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

    my($TEMPLATE) = "%6.4f";                      # 補間係数の比較桁数
    my(@Lnew) = map(((1/$_) x $_), reverse(2 .. $MO+1)); # EMアルゴリズムの初期値
    do {                                          # EMアルゴリズムのループ
        @LforTemplate = @Lnew;                        # 少々トリッキー
        @Lnew = (0) x @LforTemplate;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $TemplateMarkov[$n]->OneIteration($Tran[$n], @LforTemplate);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#Lnew));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#Lnew));
        printf(STDERR "λ = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforTemplate));

    undef(@TemplateMarkov);

    my($FILE) = "> $LAMBDA";                      # 補間係数ファイルの生成
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforTemplate)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        CharIntStr
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、文字と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスに現れる文字を対象とする。

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
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $word (&Line2Units($_)){    # 単語単位のループ
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

# 機  能 : 引数で与えられるコーパスを読み込み、文字 bigram を生成する。

sub CharMarkov{
    die "Not Implemented\n";
    warn "main::CharMarkov\n";
    my($markov) = shift;

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $word (&Line2Units($_)){    # 単語単位のループ
                next unless ($TemplateIntStr->int($word) == $TemplateIntStr->int($UT));
#                next if ($TemplateMarkov->_1gram($TemplateIntStr->int($word)) > 1); # new
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
    die "Not Implemented\n";
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
            foreach $word (&Line2Units($_)){      # 単語単位のループ
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
