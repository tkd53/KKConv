#=====================================================================================
#                        Markov3rd.pm
#                             by Shinsuke MORI
#                             Last change : 21 November 2002
#=====================================================================================

# 機  能 : マルコフモデルを実装するための仮想基底クラス
#
# 実  例 : なし
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

package Markov;

use Carp;


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new(IntStr, SIZE, FILE)
#
# 機  能 : インスタンスの生成
#            IntStr : 文字列と数値の対応関数
#          FILENAME : ファイルの名前

sub new{
    croak "Virtual function Markov::new called";
}


#-------------------------------------------------------------------------------------
#                        add
#-------------------------------------------------------------------------------------

# add(NUM, NUM, int);
#
# 機  能 : 状態 NUM から状態 NUM への遷移の頻度に int を加える。

sub add{
    croak "Virtual function Markov::add called";
}


#-------------------------------------------------------------------------------------
#                        put
#-------------------------------------------------------------------------------------

# put(FILENAME);
#
# 機  能 : ファイルに出力する。

sub put{
    croak "Virtual function Markov::put called";
}


#-------------------------------------------------------------------------------------
#                        get
#-------------------------------------------------------------------------------------

# get(FILENAME);
#
# 機  能 : ファイルから入力する

sub get{
    croak "Virtual function Markov::get called";
}


#-------------------------------------------------------------------------------------
#                        _0gram
#-------------------------------------------------------------------------------------

# _0gram
#
# 機  能 : 0-gram の頻度

sub _0gram{
    croak "Virtual function Markov::_0gram called";
}


#-------------------------------------------------------------------------------------
#                        _1gram
#-------------------------------------------------------------------------------------

# _1gram(Number)
#
# 機  能 : 1-gram の頻度
#          Number : 状態の番号

sub _1gram{
    croak "Virtual function Markov::_1gram called";
}


#-------------------------------------------------------------------------------------
#                        _2gram
#-------------------------------------------------------------------------------------

# _2gram(Number)
#
# 機  能 : 2-gram の頻度
#          Number : 状態の番号

sub _2gram{
    croak "Virtual function Markov::_2gram called";
}


#-------------------------------------------------------------------------------------
#                        _3gram
#-------------------------------------------------------------------------------------

# _3gram(Number)
#
# 機  能 : 3-gram の頻度
#          Number : 状態の番号

sub _3gram{
    croak "Virtual function Markov::_2gram called";
}


#-------------------------------------------------------------------------------------
#                        _4gram
#-------------------------------------------------------------------------------------

# _4gram(Number)
#
# 機  能 : 4-gram の頻度
#          Number : 状態の番号

sub _4gram{
    croak "Virtual function Markov::_2gram called";
}


#-------------------------------------------------------------------------------------
#                        size
#-------------------------------------------------------------------------------------

# size;
#
# 機  能 : size を返す。

sub size{
    croak "Virtual function Markov::size called";
}


#-------------------------------------------------------------------------------------
#                        add
#-------------------------------------------------------------------------------------

# add(Int, STATE, STATE);
#
# 機  能 : <STATE, STATE> の頻度に Int を加える。

sub add{
    croak "Virtual function Markov::add called";
}


#-------------------------------------------------------------------------------------
#                        inc
#-------------------------------------------------------------------------------------

# inc(STATE, STATE);
#
# 機  能 : <STATE, STATE> の頻度をインクリメントする。

sub inc{
    (@_ == 3) || die;
    my($self) = shift;

    $self->add(1, @_);
}


#-------------------------------------------------------------------------------------
#                        prob
#-------------------------------------------------------------------------------------

# prob(NUM, NUM, NUM, , NUM, λ1, λ2, λ3, λ4, λ5, λ6, λ7, λ8, λ9);
#
# 機  能 : 補間した遷移確率を返す。

sub prob{
    (@_ == 14) || die;
    my($self, $suf1, $suf2, $suf3, $suf4, $L1, $L2, $L3, $L4, $L5, $L6, $L7, $L8, $L9) = @_;

    if ($self->_3gram($suf1, $suf2, $suf3) > 0){
        return($L1*$self->_1prob($suf4)
              +$L2*$self->_2prob($suf3, $suf4)
              +$L3*$self->_3prob($suf2, $suf3, $suf4)
              +$L4*$self->_4prob($suf1, $suf2, $suf3, $suf4));
    }elsif ($self->_2gram($suf2, $suf3) > 0){
        return($L5*$self->_1prob($suf4)
              +$L6*$self->_2prob($suf3, $suf4)
              +$L7*$self->_3prob($suf2, $suf3, $suf4));
    }else{
        return($L8*$self->_1prob($suf4)
              +$L9*$self->_2prob($suf3, $suf4));
    }
}


#-------------------------------------------------------------------------------------
#                        _1prob
#-------------------------------------------------------------------------------------

# _1prob(NUM);
#
# 機  能 : 0 重マルコフモデルによる遷移確率を返す。

sub _1prob{
    (@_ == 2) || die;
    my($self, $suf2) = @_;

    return($self->_1gram($suf2)/$self->_0gram());
}


#-------------------------------------------------------------------------------------
#                        _2prob
#-------------------------------------------------------------------------------------

# _2prob(NUM, NUM);
#
# 機  能 : 1 重マルコフモデルによる遷移確率を返す。

sub _2prob{
    (@_ == 3) || die;
    my($self, $suf1, $suf2) = @_;

    return($self->_2gram($suf1, $suf2)/$self->_1gram($suf1));
}


#-------------------------------------------------------------------------------------
#                        _3prob
#-------------------------------------------------------------------------------------

# _3prob(NUM, NUM, NUM);
#
# 機  能 : 2 重マルコフモデルによる遷移確率を返す。

sub _3prob{
    (@_ == 4) || die;
    my($self, $suf1, $suf2, $suf3) = @_;

    return($self->_3gram($suf1, $suf2, $suf3)/$self->_2gram($suf1, $suf2));
}


#-------------------------------------------------------------------------------------
#                        _4prob
#-------------------------------------------------------------------------------------

# _4prob(NUM, NUM, NUM, NUM);
#
# 機  能 : 3 重マルコフモデルによる遷移確率を返す。

sub _4prob{
    (@_ == 5) || die;
    my($self, $suf1, $suf2, $suf3, $suf4) = @_;

    return($self->_4gram($suf1, $suf2, $suf3, $suf4)/$self->_3gram($suf1, $suf2, $suf3));
}


#-------------------------------------------------------------------------------------
#                        OneIteration
#-------------------------------------------------------------------------------------

# OneIteration(List, Lambda1, Lambda2, Lambda3, Lambda4, Lambda5)
#
# 機  能 : 補間係数推定の一回の繰り返し。

# 注意点 : List = [Scur, Sfol, Coef]

sub OneIteration{
    (@_ == 11) || die;
    my($self, $list, $L1, $L2, $L3, $L4, $L5, $L6, $L7, $L8, $L9) = @_;

    my($suf1, $suf2, $suf3, $suf4, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $temp);
    my($Coef_sum1, $Coef_sum2, $Coef_sum3) = (0, 0, 0);
    my($L1_new, $L2_new, $L3_new, $L4_new, $L5_new, $L6_new, $L7_new, $L8_new, $L9_new) = (0, 0, 0, 0, 0, 0, 0, 0, 0);


    foreach (@$list){
        ($suf1, $suf2, $suf3, $suf4, $Coef) = @$_;
        if ($self->_3gram($suf1, $suf2, $suf3) > 0){
            $p1 = $L1*$self->_1prob($suf4);
            $p2 = $L2*$self->_2prob($suf3, $suf4);
            $p3 = $L3*$self->_3prob($suf2, $suf3, $suf4);
            $p4 = $L4*$self->_4prob($suf1, $suf2, $suf3, $suf4);

            $L1_new += $Coef*$p1/($p1+$p2+$p3+$p4);
            $L2_new += $Coef*$p2/($p1+$p2+$p3+$p4);
            $L3_new += $Coef*$p3/($p1+$p2+$p3+$p4);
            $L4_new += $Coef*$p4/($p1+$p2+$p3+$p4);

            $Coef_sum1 += $Coef;
        }elsif ($self->_2gram($suf2, $suf3) > 0){
            $p5 = $L5*$self->_1prob($suf4);
            $p6 = $L6*$self->_2prob($suf3, $suf4);
            $p7 = $L7*$self->_3prob($suf2, $suf3, $suf4);

            $L5_new += $Coef*$p5/($p5+$p6+$p7);
            $L6_new += $Coef*$p6/($p5+$p6+$p7);
            $L7_new += $Coef*$p7/($p5+$p6+$p7);

            $Coef_sum2 += $Coef;
        }else{
            $p8 = $L8*$self->_1prob($suf4);
            $p9 = $L9*$self->_2prob($suf3, $suf4);

            $L8_new += $Coef*$p8/($p8+$p9);
            $L9_new += $Coef*$p9/($p8+$p9);

            $Coef_sum3 += $Coef;
        }
    }

    $L1_new /= $Coef_sum1;
    $L2_new /= $Coef_sum1;
    $L3_new /= $Coef_sum1;
    $L4_new /= $Coef_sum1;
    $temp = 1-($L1_new+$L2_new+$L3_new+$L4_new);
    $L1_new += $temp/4;
    $L2_new += $temp/4;
    $L3_new += $temp/4;
    $L4_new += $temp/4;

    $L5_new /= $Coef_sum2;
    $L6_new /= $Coef_sum2;
    $L7_new /= $Coef_sum2;
    $temp = 1-($L5_new+$L6_new+$L7_new);
    $L5_new += $temp/3;
    $L6_new += $temp/3;
    $L7_new += $temp/3;

    if ($Coef_sum3 > 0){
        $L8_new /= $Coef_sum3;
        $L9_new /= $Coef_sum3;
        $temp = 1-($L8_new+$L9_new);
        $L8_new += $temp/2;
        $L9_new += $temp/2;
    }else{
        ($L8_new, $L9_new) = ($L8, $L9);
    }

    return($L1_new, $L2_new, $L3_new, $L4_new, $L5_new, $L6_new, $L7_new, $L8_new, $L9_new);
}


#-------------------------------------------------------------------------------------
#                        test
#-------------------------------------------------------------------------------------

sub test{
    (@_ == 6) || die;
    my($self, $IntStr) = (shift, shift);
    my(@state) = map($IntStr->int($_), @_);

    printf(STDERR "Freq(%s %s %s %s) = %d\n", @_, $self->_4gram(@state));
    printf(STDERR "Freq(%s %s %s) = %d\n", @_[0..2], $self->_3gram(@state[0..2]));
    printf(STDERR "Freq(%s %s %s) = %d\n", @_[1..3], $self->_3gram(@state[1..3]));
    printf(STDERR "Freq(%s %s) = %d\n", @_[0, 1], $self->_2gram(@state[0, 1]));
    printf(STDERR "Freq(%s %s) = %d\n", @_[1, 2], $self->_2gram(@state[1, 2]));
    printf(STDERR "Freq(%s %s) = %d\n", @_[2, 3], $self->_2gram(@state[2, 3]));
    printf(STDERR "Freq(%s) = %d\n", @_[0], $self->_1gram(@state[0]));
    printf(STDERR "Freq(%s) = %d\n", @_[1], $self->_1gram(@state[1]));
    printf(STDERR "Freq(%s) = %d\n", @_[2], $self->_1gram(@state[2]));
    printf(STDERR "Freq(%s) = %d\n", @_[3], $self->_1gram(@state[3]));
    printf(STDERR "Freq() = %d\n", $self->_0gram());
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
