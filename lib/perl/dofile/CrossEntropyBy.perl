use bytes;
#=====================================================================================
#                       CrossEntropyBy.perl
#                             bShinsuke Mori
#                             Last change 24 June 2014
#=====================================================================================

# To Do: Morphs2... を Token2... に変更していく

do "dofile/SetVariables.perl";
do "../../lib/perl/SetVariables.perl";


#-------------------------------------------------------------------------------------
#                        Morphs2Chars
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、文字のリストを返す。
#
# 注  意 : 文は "表記/品詞 ..." となっている必要がある。

sub Morphs2Chars{
    return(map(m/(..)/g, &Morphs2Words(shift)));
}


#-------------------------------------------------------------------------------------
#                        Morphs2Types
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、文字のリストを返す。
#
# 注  意 : 文は "表記/品詞 ..." となっている必要がある。

sub Morphs2Types{
    return(map(&CharType($_), &Morphs2Chars(shift)));
}


#-------------------------------------------------------------------------------------
#                        Morphs2Words
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、単語のリストを返す。
#
# 注  意 : 文は "表記/品詞 ..." となっている必要がある。

sub Morphs2Words{
    return(map((split("/"))[0], split(" ", shift)));
}


#-------------------------------------------------------------------------------------
#                        Morphs2Parts
#-------------------------------------------------------------------------------------

# 機  能 : 引数で与えられる文を読み込み、品詞のリストを返す。
#
# 注  意 : 文は "表記/品詞 ..." となっている必要がある。

sub Morphs2Parts{
    return(map(($MorpIntStr->int($_) == $MorpIntStr->int($UT)) ?
               $UT : (split("/"))[1], split(" ", shift)));
}


#-------------------------------------------------------------------------------------
#                        eq
#-------------------------------------------------------------------------------------

# eq(TEMPLATE, ARRAYREF, ARRAYREF)
#
# 機  能 : 2 つの ARRAY を sprintf(TEMPLATE, ...) で文字列に変換して比較する
#
# 実  例 : print "True" if (eq("%5.2f", \@array1, \@array2))
#
# 注意点 : なし

sub eq{
    (@_ == 3) || die;
    my($temp, $ref1, $ref2) = @_;

    (@$ref1 eq @$ref2) || return(0);
    foreach (0 .. $#$ref1){
        (sprintf($temp, $$ref1[$_]) eq sprintf($temp, $$ref2[$_])) || return(0);
    }
    return(1);
}


#-------------------------------------------------------------------------------------
#                        単位 2-gram モデルの補間係数の読み込み
#-------------------------------------------------------------------------------------

# ReadLambda(STRING)
#
# 機  能 : STRING を接頭辞とするファイルから補間係数読み込む。
#
# 実  例 : @LforWord = &ReadLambda("WordLambda");
#
# 注意点 :

sub ReadLambda{
    (@_ == 1) || die;
    my($FILE) = shift;

    printf(STDERR "Reading %s ... ", $FILE);

    open(FILE, $FILE) || die "Can't open $FILE: $!\n";
    my(@Lambda) = map($_+0.0, split(/[ \t\n]+/, <FILE>));
    close(FILE);

    warn "Done\n";

    return(@Lambda);
}


#-------------------------------------------------------------------------------------
#                        単位 2-gram モデルの読み込み
#-------------------------------------------------------------------------------------

# Read2gramModel(STRING)
#
# 機  能 : STRING を接頭辞とするファイルから 2-gram モデルを読み込む。
#
# 実  例 : ($WordIntStr, $WordMarkov, @LforWord) = &Read2gramModel("Word");
#
# 注意点 :

sub Read2gramModel{
    (@_ == 1) || die;
    my($prefix) = shift;

    printf(STDERR "Reading %sIntStr.text, %sMarkov.db, and %sLambda ... ",
           ($prefix) x 3);

    my($IntStr) = new IntStr($prefix . "IntStr.text");

#    my($Markov) = new MarkovHashDisk($IntStr->size, $prefix . "Markov");
    my($Markov) = new MarkovHashMemo($IntStr->size, $prefix . "Markov");

    $LAMBDA = $prefix . "Lambda";
    open(LAMBDA, $LAMBDA) || die "Can't open $LAMBDA: $!\n";
    my(@Lambda) = map($_+0.0, split(/[ \t\n]+/, <LAMBDA>));
    close(LAMBDA);

    warn "Done\n";

    return($IntStr, $Markov, @Lambda);
}


#=====================================================================================
#                        END
#=====================================================================================
