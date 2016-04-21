#=====================================================================================
#                        SCFGIntStr.pm
#                             by Shinsuke MORI
#                             Last change : 26 October 1997
#=====================================================================================

# ��  ǽ : ʸ���°��(String)�� Integer �ΰ��а���б��ط�
#
# ����� : $Dmax, $Vmax �ϥ��饹�˶��̤��ѿ� (ʣ���Υ��󥹥��󥹤�����ˤ����!!)
#          �ܼ�Ū�ˤ����Ǥ���ɬ�פǤϤʤ���ñ�ʤ��ȴ����
#          ���󥹥��󥹤˸�ͭ���ѿ��ˤ�����٤��ʤꤽ�� (Perl ������)��


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

package SCFGIntStr;

@SIGN = ("NULL", "����", "����");
%SIGN = map(($SIGN[$_] => $_), (0 .. $#SIGN));


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new(FILENAME)
#
# ��  ǽ : FILENAME �γƹԤ����ǤȤߤʤ��ƥ��󥹥��󥹤��������롣
#
# ����� : �ʤ�

sub new{
    (@_ == 5) || die;
    my($type) = shift;
    my($self) = [shift, shift];
    ($Dmax, $Vmax) = (shift, shift);

    ($Dmax >  0) || die; 
    ($Vmax >  0) || die;

    return(bless($self));
}


#-------------------------------------------------------------------------------------
#                        size
#-------------------------------------------------------------------------------------

# size(STR);
#
# ��  ǽ : STR ���б����� Int ���֤���
#
# ����� : STR ����Ͽ����Ƥ��ʤ���� undef �ǤϤʤ� 0 ���֤���

sub size{
    (@_ == 1) || die;
    my($self) = @_;

    return(($$self[0]->size-1)*($$self[1]->size-1)*scalar(@SIGN)*($Dmax+1)*($Vmax+1));
#    return($$self[0]->size*$$self[1]->size*scalar(@SIGN)*($Dmax+1)*($Vmax+1));
}


#-------------------------------------------------------------------------------------
#                        int
#-------------------------------------------------------------------------------------

# int(STR);
#
# ��  ǽ : STR ���б����� Int ���֤���
#
# ����� : �ʤ�

sub int{
    (@_ == 2) || die;
    my($self, $STR) = @_;

    my($cmax, $fmax, $smax) = ($$self[0]->size, $$self[1]->size, scalar(@SIGN));
    my($dmax, $vmax) = ($Dmax+1, $Vmax+1);

    ($STR eq "Sent") && return($cmax*$fmax*$smax*$dmax*$vmax);

    my($cont, $func, $sign, $dist, $verb) = split("-", $STR);

#    printf(STDERR "%s = %s %s %s %s %s %s\n",
#           $STR, $cont, $func, $sign, $dist, $verb, $kaku);

    my($cnum) = $$self[0]->int($cont) || $$self[0]->int((split("/", $cont))[1]);
    my($fnum) = $$self[1]->int($func) || $$self[1]->int((split("/", $func))[1]);
    my($snum) = $SIGN{$sign};
    my($dnum) = $dist+0;                          # ʸ�������ͤ��Ѵ�
    my($vnum) = $verb+0;                          # ʸ�������ͤ��Ѵ�

#    printf(STDERR "(%d %d %d %d %d %d)\n", $cnum, $fnum, $snum, $dnum, $vnum, $knum);

    return($cnum+$cmax*($fnum+$fmax*($snum+$smax*($dnum+$dmax*$vnum))));
}


#-------------------------------------------------------------------------------------
#                        str
#-------------------------------------------------------------------------------------

# str(INT);
#
# ��  ǽ : INT ���б����� STR ���֤�
#
# ����� : �ʤ�

sub str{
    (@_ == 2) || die;
    my($self, $INT) = @_;

    my($cmax, $fmax, $smax) = ($$self[0]->size, $$self[1]->size, scalar(@SIGN));
    my($dmax, $vmax, $kmax) = ($Dmax+1, $Vmax+1);

    ($INT == $cmax*$fmax*$smax*$dmax*$vmax) && return("Sent"); 

    my($cnum) = $INT%$cmax;
    $INT = int($INT/$cmax);

    my($fnum) = $INT%$fmax;
    $INT = int($INT/$fmax);

    my($snum) = $INT%$smax;
    $INT = int($INT/$smax);

    my($dnum) = $INT%$dmax;
    $INT = int($INT/$dmax);

    my($vnum) = $INT%$vmax;
    $INT = int($INT/$vmax);
    
    ($INT == 0) || die;

    return(join("-", $$self[0]->str($cnum), $$self[1]->str($fnum), $SIGN[$snum],
                sprintf("%d-%d", $dnum, $vnum)));
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
