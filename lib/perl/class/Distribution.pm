#=====================================================================================
#                        Distribution.pm
#                             by Shinsuke MORI
#                             Last change : 14 April 1999
#=====================================================================================

# ��  ǽ : 0 ����Τ��������Τ֤��
#
# ��  �� : �ʤ�
#
# ������ : �ʤ�


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

package Distribution;

use Carp;


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new(FILE)
#
# ��  ǽ : ���󥹥��󥹤�����
#          FILE : �ե������̾��

sub new{
    (@_ == 1) || (@_ == 2) || die;
    my($type, $FILE) = @_;

    my($self) = {};

    $self->{"sum"} = 0;
    $self->{"ave"} = 0;
    $self->{"fre"} = [];

    bless($self);

    $self->get($FILE) if (defined($FILE));

    return($self);
}


#-------------------------------------------------------------------------------------
#                        put
#-------------------------------------------------------------------------------------

# put(FILENAME);
#
# ��  ǽ : �ե�����˽��Ϥ��롣

sub put{
    (@_ == 2) || die;
    my($self, $FILE) = @_;

    open(FILE, "> $FILE") || die "Can't open $FILE: $!\n";
    print FILE join("\n", @{$self->{"fre"}}), "\n";
    close(FILE);
}


#-------------------------------------------------------------------------------------
#                        get
#-------------------------------------------------------------------------------------

# get(FILENAME);
#
# ��  ǽ : �ե����뤫�����Ϥ���

sub get{
    (@_ == 2) || die;
    my($self, $FILE) = @_;

    @{$self->{"fre"}} = ();

    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    while (<FILE>){
        push(@{$self->{"fre"}}, $_+0);
        $self->{"sum"} += $_;
    }
    close(FILE);

    $self->setave;
}


#-------------------------------------------------------------------------------------
#                        add
#-------------------------------------------------------------------------------------

# add(Int, STATE);
#
# ��  ǽ : <STATE> �����٤� Int ��ä��롣

sub add{
    (@_ == 3) || die;
    my($self, $val, $suf) = @_;

    $self->{"fre"}[$suf] += $val;
    $self->{"sum"} += $val;
}


#-------------------------------------------------------------------------------------
#                        inc
#-------------------------------------------------------------------------------------

# inc(STATE, STATE);
#
# ��  ǽ : <STATE, STATE> �����٤򥤥󥯥���Ȥ��롣

sub inc{
    (@_ == 2) || die;
    my($self, $suf) = @_;

    $self->{"fre"}[$suf]++;
    $self->{"sum"}++;
}


#-------------------------------------------------------------------------------------
#                        setave
#-------------------------------------------------------------------------------------

# setave;
#
# ��  ǽ : �ؤ�����Τ�������

sub setave{
    (@_ == 1) || die;
    my($self) = @_;

    for ($i = 0; $i < @{$self->{"fre"}}; $i++){
        $self->{"ave"} += $i*$self->{"fre"}[$i];
    }
    $self->{"ave"} /= $self->{"sum"};
}


#-------------------------------------------------------------------------------------
#                        _1prob
#-------------------------------------------------------------------------------------

# _1prob(NUM);
#
# ��  ǽ : ��֤������ܳ�Ψ���֤���

sub _1prob{
    (@_ == 2) || die;
    my($self, $suf) = @_;

    return($self->{"fre"}[$suf]/$self->{"sum"});
}


#-------------------------------------------------------------------------------------
#                        prob
#-------------------------------------------------------------------------------------

# prob(NUM, L1, L2);
#
# ��  ǽ : ��֤������ܳ�Ψ���֤���

sub prob{
    (@_ == 4) || die;
    my($self, $suf, $L1, $L2) = @_;

    return($L1*$self->_1prob($suf)+$L2*&PoissonDistribution($self->{"ave"}, $suf));
}


#-------------------------------------------------------------------------------------
#                        logP
#-------------------------------------------------------------------------------------

# logP(NUM, ��1, ��2);
#
# ��  ǽ : ��֤������ܳ�Ψ���֤���

sub logP{
    (@_ == 4) || die;
    my($self) = shift;

    return(-log($self->prob(@_)));
}


#-------------------------------------------------------------------------------------
#                        OneIteration
#-------------------------------------------------------------------------------------

# OneIteration(List, Lambda1, Lambda2)
#
# ��  ǽ : ��ַ�������ΰ��η����֤���
#
# ������ : List = [Scur, Coef]

sub OneIteration{
    (@_ == 4) || die;
    my($self, $list, $L1, $L2) = @_;

    (@$list > 0) || return($L1, $L2);             # Held-out Data ���ʤ����

    my($Scur, $Coef, $p1, $p2, $temp);
    my($Coef_sum, $L1_new, $L2_new) = (0, 0, 0);
    foreach (@$list){
        ($Scur, $Coef) = @$_;
        $p1 = $L1*$self->_1prob($Scur);
        $p2 = $L2*&PoissonDistribution($self->{"ave"}, $Scur);
        $L1_new += $Coef*$p1/($p1+$p2);
        $L2_new += $Coef*$p2/($p1+$p2);
        $Coef_sum += $Coef;
    }

    $L1_new /= $Coef_sum;
    $L2_new /= $Coef_sum;

    $temp = 1-($L1_new+$L2_new);
    $L1_new += $temp/2;
    $L2_new += $temp/2;

    return($L1_new, $L2_new);
}


#-------------------------------------------------------------------------------------
#                        PoissonDistribution
#-------------------------------------------------------------------------------------

# ��  ǽ : Poisson ʬ��
#
# ��  �� : $m ��ʿ����

sub PoissonDistribution{
    (@_ == 2) || die;
    my($m, $k) = @_;

    return(($m**$k)*exp(-$m)/&Factorial($k));
}


#-------------------------------------------------------------------------------------
#                        Factorial
#-------------------------------------------------------------------------------------

# ��  ǽ : ����

sub Factorial{
    (@_ == 1) || die;
    my($n) = @_;
    my($F) = 1;

    $F *= $n-- while ($n > 1);

    return($F);
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================