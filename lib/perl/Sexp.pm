#=====================================================================================
#                        Sexp.pm
#                             by Shinsuke MORI
#                             Last change : 2 August 1997
#=====================================================================================

# ��  ǽ : �����Ӽ��ȸ��ʤ������������󶡤���
#
# ��  �� : �ʤ�
#
# ������ : �ʤ�


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

package Sexp;


#-------------------------------------------------------------------------------------
#                        FCP
#-------------------------------------------------------------------------------------

# FCP(POS, ARRAYREF)
#
# ��  ǽ : POS �ΰ��֤γ�̤��б������̤������˸����ä�õ�������ΰ��֤��֤���
#
# ��  �� : &FCP($j, \@array);
#
# ������ : �äˤʤ�

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
# ��  ǽ : POS �ΰ��֤γ�̤��б������̤�����˸����ä�õ�������ΰ��֤��֤���
#
# ��  �� : &BCP($j, \@array);
#
# ������ : �äˤʤ�

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

# ��ʣ��������Ф������

sub DDB{
    my($array) = @_;
    my($i, $j, $depth);

    for ($i = 0; $i+3 < @$array; $i++){             # ��ʣ��������Ф������
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

# ���ǿ������γ���Ф������

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