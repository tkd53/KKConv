#=====================================================================================
#                        RectMarkov.pm
#                             by Shinsuke MORI
#                             Last change : 23 April 1999
#=====================================================================================

# 機  能 : マルコフモデルを実装するための仮想基底クラス
#
# 実  例 : なし
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

package RectMarkov;

use Carp;


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new(IntStr, SIZE, SIZE, FILE)
#
# 機  能 : インスタンスの生成
#            IntStr : 文字列と数値の対応関数
#          FILENAME : ファイルの名前

sub new{
    croak "Virtual function RectMarkov::new called";
}


#-------------------------------------------------------------------------------------
#                        put
#-------------------------------------------------------------------------------------

# put(FILENAME);
#
# 機  能 : ファイルに出力する。

sub put{
    croak "Virtual function RectMarkov::put called";
}


#-------------------------------------------------------------------------------------
#                        get
#-------------------------------------------------------------------------------------

# get(FILENAME);
#
# 機  能 : ファイルから入力する

sub get{
    croak "Virtual function RectMarkov::get called";
}


#-------------------------------------------------------------------------------------
#                        _0gram
#-------------------------------------------------------------------------------------

# _0gram
#
# 機  能 : 0-gram の頻度

sub _0gram{
    croak "Virtual function RectMarkov::_0gram called";
}


#-------------------------------------------------------------------------------------
#                        _1gramLe
#-------------------------------------------------------------------------------------

# _1gramLe(Number)
#
# 機  能 : 1-gram の頻度
#          Number : 状態の番号

sub _1gramLe{
    croak "Virtual function RectMarkov::_1gramLe called";
}


#-------------------------------------------------------------------------------------
#                        _1gram
#-------------------------------------------------------------------------------------

# _1gramRi(Number)
#
# 機  能 : 1-gram の頻度
#          Number : 状態の番号

sub _1gramRi{
    croak "Virtual function RectMarkov::_1gramRi called";
}


#-------------------------------------------------------------------------------------
#                        _2gram
#-------------------------------------------------------------------------------------

# _2gram(Number)
#
# 機  能 : 2-gram の頻度
#          Number : 状態の番号

sub _2gram{
    croak "Virtual function RectMarkov::_2gram called";
}


#-------------------------------------------------------------------------------------
#                        size
#-------------------------------------------------------------------------------------

# size;
#
# 機  能 : size を返す。

sub size{
    croak "Virtual function RectMarkov::size called";
}


#-------------------------------------------------------------------------------------
#                        add
#-------------------------------------------------------------------------------------

# add(Int, STATE, STATE);
#
# 機  能 : <STATE, STATE> の頻度に Int を加える。

sub add{
    croak "Virtual function RectMarkov::add called";
}


#-------------------------------------------------------------------------------------
#                        inc
#-------------------------------------------------------------------------------------

# inc(STATE, STATE);
#
# 機  能 : <STATE, STATE> の頻度をインクリメントする。

sub inc{
    croak "Virtual function RectMarkov::inc called";
}


#-------------------------------------------------------------------------------------
#                        logP
#-------------------------------------------------------------------------------------

# logP(NUM, NUM, λ0, λ1, λ2, λ3, λ4);
#
# 機  能 : 補間した遷移確率を返す。

sub logP{
    (@_ == 8) || die;
#    (@_ == 8) || croak;
    my($self) = shift;

    return(-log($self->prob(@_)));
}


#-------------------------------------------------------------------------------------
#                        prob
#-------------------------------------------------------------------------------------

# prob(NUM, NUM, λ0, λ1, λ2, λ3, λ4);
#
# 機  能 : 補間した遷移確率を返す。

sub prob{
    (@_ == 8) || die;
    my($self, $suf1, $suf2, $L0, $L1, $L2, $L3, $L4) = @_;

    if ($self->_1gramLe($suf1) > 0){
        return($L0*$self->_0prob()
              +$L1*$self->_1prob($suf2)
              +$L2*$self->_2prob($suf1, $suf2));
    }else{
        return($L3*$self->_0prob()
              +$L4*$self->_1prob($suf2));
    }
}


#-------------------------------------------------------------------------------------
#                        _0prob
#-------------------------------------------------------------------------------------

# _0prob(NUM);
#
# 機  能 : 0 重マルコフモデルによる遷移確率を返す。

sub _0prob{
    (@_ == 1) || die;
    my($self) = @_;

    return(1/$self->size);
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

    return($self->_1gramRi($suf2)/$self->_0gram());
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

    return($self->_2gram($suf1, $suf2)/$self->_1gramLe($suf1));
}


#-------------------------------------------------------------------------------------
#                        OneIteration
#-------------------------------------------------------------------------------------

# OneIteration(List, Lambda0, Lambda1, Lambda2, Lambda3, Lambda4)
#
# 機  能 : 補間係数推定の一回の繰り返し。

# 注意点 : List = [Scur, Sfol, Coef]

sub OneIteration{
    (@_ == 7) || die;
    my($self, $list, $L0, $L1, $L2, $L3, $L4) = @_;

    my($Scur, $Sfol, $Coef, $p0, $p1, $p2, $p3, $p4, $temp);
    my($Coef_sum1, $Coef_sum2) = (0, 0);
    my($L0_new, $L1_new, $L2_new, $L3_new, $L4_new) = (0, 0, 0, 0, 0);
    foreach (@$list){
        ($Scur, $Sfol, $Coef) = @$_;
        if ($self->_1gramLe($Scur) > 0){
            $p0 = $L0*$self->_0prob();
            $p1 = $L1*$self->_1prob($Sfol);
            $p2 = $L2*$self->_2prob($Scur, $Sfol);

            $L0_new += $Coef*$p0/($p0+$p1+$p2);
            $L1_new += $Coef*$p1/($p0+$p1+$p2);
            $L2_new += $Coef*$p2/($p0+$p1+$p2);

            $Coef_sum1 += $Coef;
        }else{
            $p3 = $L3*$self->_0prob();
            $p4 = $L4*$self->_1prob($Sfol);

            $L3_new += $Coef*$p3/($p3+$p4);
            $L4_new += $Coef*$p4/($p3+$p4);

            $Coef_sum2 += $Coef;
        }
    }

    if ($Coef_sum1 > 0){
        $L0_new /= $Coef_sum1;
        $L1_new /= $Coef_sum1;
        $L2_new /= $Coef_sum1;
        $temp = 1-($L0_new+$L1_new+$L2_new);
        $L0_new += $temp/3;
        $L1_new += $temp/3;
        $L2_new += $temp/3;
    }else{
        $L0_new = $L0;
        $L1_new = $L1;
        $L2_new = $L2;
    }

    if ($Coef_sum2 > 0){
        $L3_new /= $Coef_sum2;
        $L4_new /= $Coef_sum2;
        $temp = 1-($L3_new+$L4_new);
        $L3_new += $temp/2;
        $L4_new += $temp/2;
    }else{
        $L3_new = $L3;
        $L4_new = $L4;
    }

    return($L0_new, $L1_new, $L2_new, $L3_new, $L4_new);
}


#-------------------------------------------------------------------------------------
#                        test
#-------------------------------------------------------------------------------------

sub test{
    (@_ == 5) || die;
    my($self, $IntStr1, $IntStr2) = (shift, shift, shift);
    my(@state) = ($IntStr1->int($_[0]), $IntStr2->int($_[1]));

    printf(STDERR "  Freq(%s, %s) = %d\n", @_, $self->_2gram(@state));
    printf(STDERR "  Freq(%s) = %d\n", @_[0], $self->_1gramLe(@state[0]));
    printf(STDERR "  Freq(%s) = %d\n", @_[1], $self->_1gramRi(@state[1]));
    printf(STDERR "  Freq() = %d\n", $self->_0gram());
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
