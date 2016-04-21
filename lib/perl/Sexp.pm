#=====================================================================================
#                        Sexp.pm
#                             by Shinsuke MORI
#                             Last change : 2 August 1997
#=====================================================================================

# 機  能 : 配列をＳ式と見なし、その操作を提供する
#
# 実  例 : なし
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

package Sexp;


#-------------------------------------------------------------------------------------
#                        FCP
#-------------------------------------------------------------------------------------

# FCP(POS, ARRAYREF)
#
# 機  能 : POS の位置の括弧に対応する括弧を前方に向かって探し、その位置を返す。
#
# 実  例 : &FCP($j, \@array);
#
# 注意点 : 特になし

sub FCP{
#    (@_ == 2) || die;
    my($pos, $array) = @_;
    my($depth);

    for ($pos++, $depth = 1; $depth > 0; $pos++){
        $depth++ if (substr($$array[$pos],  0, 1) eq "(");
        $depth-- if (substr($$array[$pos], -1, 1) eq ")");
    }

    return($pos-1);
}
        

#-------------------------------------------------------------------------------------
#                        BCP
#-------------------------------------------------------------------------------------

# BCP(POS, ARRAYREF)
#
# 機  能 : POS の位置の括弧に対応する括弧を後方に向かって探し、その位置を返す。
#
# 実  例 : &BCP($j, \@array);
#
# 注意点 : 特になし

sub BCP{
#    (@_ == 2) || die;
    my($pos, $array) = @_;
    my($depth);

    for ($pos--, $depth = 1; $depth > 0; $pos--){
        $depth-- if (substr($$array[$pos],  0, 1) eq "(");
        $depth++ if (substr($$array[$pos], -1, 1) eq ")");
    }

    return($pos+1);
}
        

#-------------------------------------------------------------------------------------
#                        DDB
#-------------------------------------------------------------------------------------

# 重複した括弧対を取り除く

sub DDB{
    my($array) = @_;
    my($i, $j, $depth);

    for ($i = 0; $i+3 < @$array; $i++){             # 重複した括弧対を取り除く
        if (($$array[$i] eq "(") && ($$array[$i+1] eq "(")){
            for ($j = $i+2, $depth = 1; ; $j++){
                $depth++ if ($$array[$j] eq "(");
                $depth-- if ($$array[$j] eq ")");
                last if ($depth == 0);
            }
            if ($$array[$j+1] eq ")"){
                splice(@$array, $i, 1);
                splice(@$array, $j, 1);
                $i--;
            }
        }
    }
}


#-------------------------------------------------------------------------------------
#                        DSB
#-------------------------------------------------------------------------------------

# 要素数が１の括弧対を取り除く

sub DSB{
    my($array) = @_;
    my($i);

    for ($i = 0; $i+2 < @$array; $i++){
        if (($$array[$i] eq "(") && ($$array[$i+2] eq ")")){
            splice(@$array, $i, 1);
            splice(@$array, $i+1, 1);
        }
    }
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
