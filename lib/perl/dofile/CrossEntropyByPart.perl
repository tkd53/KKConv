#=====================================================================================
#                       CrossEntropyByPart.perl
#                             bShinsuke Mori
#                             Last change 19 June 2010
#=====================================================================================

#-------------------------------------------------------------------------------------
#                        PartIntStr
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、品詞と数字の対応関係を生成する。
#
# 注  意 : $MIN 以上の部分コーパスのに現れる文字を対象とする。

sub PartIntStr{
    warn "main::PartIntStr\n";
    my($FILE) = shift;

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", $UT, $BT, @Part), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        PartMarkov
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、形態素レベルのマルコフモデルを生成する

sub PartMarkov{
    warn "main::PartMarkov\n";
    my($markov) = shift(@_);

    foreach $CORPUS (@_){
        printf(STDERR "  %02d:%02d:%02d  ", (localtime(time))[2, 1, 0]);
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        warn "Reading $CORPUS\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            @stat = map($PartIntStr->int($_), (($BT) x $MO, split, $BT));
            grep(! $markov->inc(@stat[$_-$MO .. $_]), ($MO .. $#stat)); 
        }
        close(CORPUS);
    }
    foreach (@Part){                              # F(UT) > 0 を保証する (floaring)
        $markov->inc(($MorpIntStr->int($_)) x ($MO+1));
    }
}


#-------------------------------------------------------------------------------------
#                        CalcPartLambda
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられるコーパスを読み込み、形態素レベルのマルコフモデルを生成する

sub CalcPartLambda{
    (@_ == 2) || die;
    my($MO) = shift;                              # マルコフモデルの次数
    my($LAMBDA) = shift;                          # 補間係数のファイル名

    my(@PartMarkov);                              # クロスバリデーション用のモデル

    foreach $n (@Kcross){                         # 削除補間用のマルコフモデルの生成
        $PartMarkov[$n] = new MarkovHashMemo($PartIntStr->size);
#        $FILE = sprintf("PartMarkov%02d", $n);
#        $PartMarkov[$n] = new MarkovHashDisk($PartIntStr->size, $FILE);
        &PartMarkov($PartMarkov[$n],
                    map(sprintf($CTEMPL, $_), grep($_ != $n, @Kcross)));
        $PartMarkov[$n]->test($PartIntStr, @PartMarkovTest);
#        $PartMarkov[$n]->put(sprintf("PartMarkov%02d", $n));
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
            my(@stat) = map($PartIntStr->int($_), (($BT) x $MO, split, $BT));
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
        @LforPart = @Lnew;                    # 少々トリッキー
        @Lnew = (0) x @LforPart;
        foreach $n (@Kcross){                     # k-fold cross validation
            print STDERR $n, " ";
            my(@Ltmp) = $PartMarkov[$n]->OneIteration($Tran[$n], @LforPart);
            grep(! ($Lnew[$_] += $Ltmp[$_]), (0 .. $#LforPart));
        }
        @Lnew = map($Lnew[$_]/scalar(@Kcross), (0 .. $#LforPart));
        printf(STDERR "λ = (%s)\n", join(" ", map(sprintf($TEMPLATE, $_), @Lnew)));
    } while (! &eq($TEMPLATE, \@Lnew, \@LforPart));
    
    undef(@PartMarkov);

    my($FILE) = "> $LAMBDA";                          # 補間係数ファイルの生成
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    print FILE join(" ", map(sprintf($TEMPLATE, $_), @LforPart)), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        MorpVector
#-------------------------------------------------------------------------------------

# 機  能 : 各形態素の頻度をベクトルを生成する。
#
# 注  意 : @MorpVector は大域変数である。

sub MorpVector{
    warn "main::MorpVector\n";
    my(@CORPUS) = @_;
    foreach $CORPUS (@CORPUS){
        open(CORPUS) || die "Can't open $CORPUS: $!\n";
        while (<CORPUS>){                         # 文単位のループ
            ($.%$STEP == 0) || next;
            foreach $morp (split){
                $MorpVector[$MorpIntStr->int($morp)]++;
            }
        }
        close(CORPUS);
    }
}


#=====================================================================================
#                        END
#=====================================================================================
