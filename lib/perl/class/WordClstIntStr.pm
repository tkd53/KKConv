#=====================================================================================
#                        WordClstIntStr.pm
#                             by Shinsuke Mori
#                             Last change : 17 May 2008
#=====================================================================================

# 機  能 : 単純マルコフモデルをハッシュを用いて実装する。
#
# 実  例 : なし
#
# 注意点 : 状態列からハッシュキーへの関数は連接であり、これが単射となる必要がある。


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

require "class/IntStr.pm";

package WordClstIntStr;
@ISA = qw( IntStr );


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new()
# new(FILENAME)
#
# 機  能 : FILENAME の各行を要素とみなしてインスタンスを生成する。
#
# 注意点 : なし

sub new{
    (@_ == 3) || die;

    my($type, @FILE) = @_;
    my($self) = {};

    $self->{"size"} = 0;
    $self->{"IntStr"} = [];                       # Int から Str への写像
    $self->{"StrInt"} = {};                       # Str から Int への写像
    $self->{"WordClst"} = {};                     # Word から Clst への写像

    open(FILE, $FILE[0]) || die "Can't open $FILE[0]: $!\n";
    $self->{"size"} = chomp(@{$self->{"IntStr"}} = <FILE>);
    close(FILE);

    foreach (0 .. $#{$self->{"IntStr"}}){
        ${$self->{"StrInt"}}{${$self->{"IntStr"}}[$_]} = $_;
    }

    open(FILE, $FILE[1]) || die "Can't open $FILE[1]: $!\n";
    while (chop($_ = <FILE>)){
        my($word, $cstr) = split;
#        printf("%s => %s\n", $word, $cstr);

        ${$self->{"WordClst"}}{$word} = $cstr;
    }
    close(FILE);

    return(bless($self));
}


#-------------------------------------------------------------------------------------
#                        int
#-------------------------------------------------------------------------------------

# int(WORD);
#
# 機  能 : WORD に対応する Int を返す。
#
# 注意点 : BT か UT の区別は $self->{"StrInt"} に任せている

sub int{
    (@_ == 2) || die;
    my($self, $word) = @_;

    my($clst) = ${$self->{"WordClst"}}{$word};

    if (defined($clst)){                          # 既知語の場合
        return(${$self->{"StrInt"}}{$clst});
    }else{                                        # 未知語(UT)または BT の場合
        return(${$self->{"StrInt"}}{$word});
    }
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
