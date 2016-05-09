use bytes;

#=====================================================================================
#                        Parallel.pm
#                             by Shinsuke MORI
#                             Last change : 11 February 1996
#=====================================================================================

# 機  能 : 二つの配列を並行に表示する。
#
# 実  例 : なし
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
#                        parallel
#-------------------------------------------------------------------------------------

# parallel(COLUMN, ARRAYREF1, ARRAYREF2, SEPARATOR)
# parallel(COLUMN, ARRAYREF1, ARRAYREF2)
#
# 機  能 : ARRAYREF1 と ARRAYREF2 を COLUMN におさまるように、並行に表示する。
#          各行の間に SEPARATOR を表示する。
#
# 実  例 : $Line = new Line ($filename);
#
# 注意点 : 特になし

sub parallel{
    (@_ == 3) || (@_ == 4) || die;
    my($COLUMN, $ARRAY1, $ARRAY2, $SEPARA) = @_;
#    printf(STDERR "parallel: COLUMN = %d\nARRAY1 = %s\nARRAY2 = %s\n", $COLUMN,
#           join(" ", @$ARRAY1), join(" ", @$ARRAY2));
    my($suf1, $suf2, $pos);

    for ($suf1 = $suf2 = 0; $suf1 < @$ARRAY1 || $suf2 < @$ARRAY2; ){
        if ($suf1 < @$ARRAY1){
            print $$ARRAY1[$suf1];
            $pos = length($$ARRAY1[$suf1]);
            $suf1++;
            while ($pos+1+length($$ARRAY1[$suf1]) <= $COLUMN){
                print " ", $$ARRAY1[$suf1];
                $pos += 1+length($$ARRAY1[$suf1]);
                $suf1++;
            }
        }
        print "\n";
        if ($suf2 < @$ARRAY2){
            print $$ARRAY2[$suf2];
            $pos = length($$ARRAY2[$suf2]);
            $suf2++;
            while ($pos+1+length($$ARRAY2[$suf2]) <= $COLUMN){
                print " ", $$ARRAY2[$suf2];
                $pos += 1+length($$ARRAY2[$suf2]);
                $suf2++;
            }
        }
        print "\n";
        print $SEPARA;
    }
}


#-------------------------------------------------------------------------------------
#                        align
#-------------------------------------------------------------------------------------

# align(COLUMN, ARRAYREF1, ARRAYREF2, SEPARATOR)
#
# 機  能 : ARRAYREF1 と ARRAYREF2 を COLUMN におさまるように、対応させて表示する。
#          各行の間に SEPARATOR を表示する。
#
# 実  例 : $Line = new Line ($filename);
#
# 注意点 : 参照渡しなのでリストの内容が書き換えられる。


sub align{
    (@_ == 3) || (@_ == 4) || die;
    my($COLUMN, $ARRAY1, $ARRAY2, $SEPARA) = @_;
    my($i, $j, $pos);

    (@$ARRAY1 == @$ARRAY2) || die "Length miss match!";

    for ($i = 0; $i < @$ARRAY1; $i++){             # スペースのパディング
        if (length($$ARRAY1[$i]) > length($$ARRAY2[$i])){
            $$ARRAY2[$i] .= " " x (length($$ARRAY1[$i])-length($$ARRAY2[$i]));
        }else{
            $$ARRAY1[$i] .= " " x (length($$ARRAY2[$i])-length($$ARRAY1[$i]));
        }
    }

    for ($i = 0; $i < @$ARRAY1; $i = $j+1){
        for ($j = $i+1; $j < @$ARRAY1; $j++){
            last if (length(join(" ", @$ARRAY1[$i .. $j+1])) > $COLUMN);
        }
        print join(" ", @$ARRAY1[$i .. $j]), "\n";
        print join(" ", @$ARRAY2[$i .. $j]), "\n";
        print $SEPARA;
    }
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
