#=====================================================================================
#                       CrossEntropyByClst.perl
#                             bShinsuke Mori
#                             Last change 22 July 2010
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        ClstMarkov
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、形態素レベルのマルコフモデルを生成する

sub ClstMarkov{
    warn "main::ClstMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            @stat = map($ClstIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
#            print STDERR join(" ", map($ClstIntStr->str($_), @stat)), "\n";
#            exit(0);
#            @stat = map($ClstIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat)); 
        }
        close(CORPUS);
    }
    foreach (@Part){                              # F(UT) > 0 を保証する (floaring)
        $markov->inc(($ClstIntStr->int($_)) x ($MO+1));
    }
}


#-------------------------------------------------------------------------------------
#                        CalcClstLambda
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、形態素レベルのマルコフモデルを生成する

sub CalcClstLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # マルコフモデルの次数
    my($LAMBDA) = shift;                          # 補間係数のファイル名

    my(@ClstMarkov);                              # クロスバリデーション用のモデル

    foreach $n (@Kcross){                         # 削除補間用のマルコフモデルの生成
        $ClstMarkov[$n] = new MarkovHashMemo($ClstIntStr->size);
#        $FILE = sprintf("ClstMarkov%02d", $n);
#        $ClstMarkov[$n] = new MarkovHashDisk($ClstIntStr->size, $FILE);
        &ClstMarkov($ClstMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $ClstMarkov[$n]->test($ClstIntStr, @ClstMarkovTest);
#        $ClstMarkov[$n]->put(sprintf("ClstMarkov%02d", $n));
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
            my(@stat) = map($ClstIntStr->int($_), (($BT) x $MO, &Line2Units($_), $BT));
#            my(@stat) = map($ClstIntStr->int($_), (($BT) x $MO, split, $BT));
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
        @LforClst = @Lnew;                    # 少々トリッキー
        @Lnew = (0) x @LforClst;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $ClstMarkov[$n]->OneIteration($Tran[$n], @LforClst);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforClst));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforClst));
        printf(STDERR "λ = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforClst));
    
    undef(@ClstMarkov);

    my($FILE) = "> $LAMBDA";                          # 補間係数ファイルの生成
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforClst)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        単位 2-gram モデルの読み込み
#-------------------------------------------------------------------------------------

# ClstRead2gramModel(STRING)
#
# 機  能 : STRING を接頭辞とするファイルから 2-gram モデルを読み込む。
#
# 実  例 : ($ClstIntStr, $ClstMarkov, @LforClst) = &ClstRead2gramModel("Clst");
#
# 注意点 : 

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
