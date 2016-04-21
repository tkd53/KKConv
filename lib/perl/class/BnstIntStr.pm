#=====================================================================================
#                        BnstIntStr.pm
#                             by Shinsuke MORI
#                             Last change : 23 August 1997
#=====================================================================================

# ��  ǽ : Integer �� String �ΰ��а���б��ط�
#
# ����� : �ʤ�


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

require "class/IntStr.pm";

package BnstIntStr;
@ISA = qw( IntStr );


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new(FILENAME)
#
# ��  ǽ : FILENAME �γƹԤ����ǤȤߤʤ��ƥ��󥹥��󥹤��������롣
#
# ����� : �ʤ�

sub new{
    (@_ == 2) || die;
    my($type, $FILE) = @_;
    my($self) = {};

    $self->{"size"} = 0;
    $self->{"IntStr"} = [];                       # Int ���� Str �ؤμ���
    $self->{"StrInt"} = {};                       # Str ���� Int �ؤμ���

    (-e $FILE) || die;

    warn "IntStr::new $FILE exist\n";
    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    $self->{"size"} = chomp(@{$self->{"IntStr"}} = <FILE>);
    close(FILE);
    
    foreach (0..$#{$self->{"IntStr"}}){
        ${$self->{"StrInt"}}{${$self->{"IntStr"}}[$_]} = $_;
    }

    return(bless($self));
}


#-------------------------------------------------------------------------------------
#                        int
#-------------------------------------------------------------------------------------

# int(STR);
#
# ��  ǽ : STR ���б����� Int ���֤���
#
# ����� : STR ����Ͽ����Ƥ��ʤ���� undef �ǤϤʤ� 0 ���֤���

sub int{
    (@_ == 2) || die;
    my($self, $STR) = @_;

    $str = &BnstIntStr::level0($STR);
    (${$self->{"StrInt"}}{$str}) && return(${$self->{"StrInt"}}{$str});

    $str = &BnstIntStr::level1($STR);
    (${$self->{"StrInt"}}{$str}) && return(${$self->{"StrInt"}}{$str});

    $str = &BnstIntStr::level2($STR);
    (${$self->{"StrInt"}}{$str}) && return(${$self->{"StrInt"}}{$str});

    $str = &BnstIntStr::level3($STR);
    (${$self->{"StrInt"}}{$str}) && return(${$self->{"StrInt"}}{$str});

    $str = &BnstIntStr::level0($STR);
    printf(STDERR "BnstIntStr::int(%s) = %d\n", ${$self->{"StrInt"}}{$str}, $str);

    $str = &BnstIntStr::level1($STR);
    printf(STDERR "BnstIntStr::int(%s) = %d\n", ${$self->{"StrInt"}}{$str}, $str);

    $str = &BnstIntStr::level2($STR);
    printf(STDERR "BnstIntStr::int(%s) = %d\n", ${$self->{"StrInt"}}{$str}, $str);

    $str = &BnstIntStr::level3($STR);
    printf(STDERR "BnstIntStr::int(%s) = %d\n", ${$self->{"StrInt"}}{$str}, $str);
    warn "\n";

    return(0);
}

sub level0{                                       # Back-off Level 0
    return(shift);
}

sub level1{                                       # Back-off Level 1
    my($cont, $func, $sign, @case) = split("-", shift);
    if ($case[0] eq "PT"){
        return(join("-", $cont, $func, $sign, "PT"));
    }else{
        return(join("-", $cont, $func, $sign));
    }
}

sub level2{                                       # Back-off Level 2
    my($cont, $func, $sign, @case) = split("-", shift);
    $cont =~ s|[^/]+/([^/]+)|$1|;
    if ($case[0] eq "PT"){
        return(join("-", $cont, $func, $sign, "PT"));
    }else{
        return(join("-", $cont, $func, $sign));
    }
}
    
sub level3{                                       # Back-off Level 3
    my($cont, $func, $sign, @case) = split("-", shift);
    $cont =~ s|[^/]+/([^/]+)|$1|;
    $func =~ s|[^/]+/([^/]+)|$1|;
    if ($case[0] eq "PT"){
        return(join("-", $cont, $func, $sign, "PT"));
    }else{
        return(join("-", $cont, $func, $sign));
    }
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
