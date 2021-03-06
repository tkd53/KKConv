use bytes;

#=====================================================================================
#                        FancyPrint.pm
#                             by Shinsuke MORI
#                             Last change : 9 May 2006
#=====================================================================================

# 機  能 : ディスプレイへの表示
#
# 実  例 : なし
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

require "MinMax.pm";


#-------------------------------------------------------------------------------------
#                        DeleteCommas
#-------------------------------------------------------------------------------------

# 機  能 : 位取りのコンマを含む文字列を数値に変換する
#
# 注意点 : なし

sub DeleteCommas{
    (@_ == 1) || die;
    $_ = shift;
    s/,//g;
    return($_+0);
}


#-------------------------------------------------------------------------------------
#                        InsertCommas
#-------------------------------------------------------------------------------------

# 機  能 : 数字を位取りのコンマを含む文字列に変換する
#
# 注意点 : なし

sub InsertCommas{
    (@_ == 1) || die;
    my($temp) = sprintf("%d", shift);
    my(@elem) = ();
    while ($temp =~ s/(\d)(\d\d\d)$/$1/){
        unshift(@elem, $2);
    }
    return(join(",", $temp, @elem));
}


#-------------------------------------------------------------------------------------
#                        PrintStringArray
#-------------------------------------------------------------------------------------

sub PrintStringArray{
    my($maxlen) = 0;

    foreach (@_){
        $maxlen = &max($maxlen, length);
    }

    my($column) = int(($COLUMNS-1)/($maxlen+2));
    my($format) = sprintf("  %%-%ds", $maxlen);

#    printf(STDERR "(maxlen, column, format) = (%d, %d, %s)\n",
#           $maxlen, $column, $format);

    for ($i = 0; $i < @_; $i++){
        printf($format, $_[$i]);
        print "\n" if (($i+1)%$column == 0);
    }
    print "\n" if ($i%$column != 0);
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
