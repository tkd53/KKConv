use bytes;
#=====================================================================================
#                        SetVariablesForKUC.perl
#                             by Shinsuke Mori
#                             Last change : 14 May 2008
#=====================================================================================

# 機  能 : 京都大学コーパスのための定数の定義
#
# 注  意 : なし


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

$CTEMPL = "../../../corpus/KUC%02d.morphs";          # コーパスのファイル名の生成の雛型

@Part = qw(感動詞：＊：＊：＊
           形容詞：＊：イ形容詞アウオ段：タ形
           形容詞：＊：イ形容詞アウオ段：タ系連用テ形
           形容詞：＊：イ形容詞アウオ段：基本形
           形容詞：＊：イ形容詞アウオ段：基本条件形
           形容詞：＊：イ形容詞アウオ段：基本連用形
           形容詞：＊：イ形容詞アウオ段：語幹
           形容詞：＊：イ形容詞アウオ段：文語基本形
           形容詞：＊：イ形容詞アウオ段：文語連体形
           形容詞：＊：イ形容詞イ段：タ形
           形容詞：＊：イ形容詞イ段：基本形
           形容詞：＊：イ形容詞イ段：基本連用形
           形容詞：＊：イ形容詞イ段：語幹
           形容詞：＊：イ形容詞イ段特殊：タ形
           形容詞：＊：イ形容詞イ段特殊：基本形
           形容詞：＊：イ形容詞イ段特殊：基本連用形
           形容詞：＊：タル形容詞：基本連用形
           形容詞：＊：タル形容詞：語幹
           形容詞：＊：ナノ形容詞：ダ列タ形
           形容詞：＊：ナノ形容詞：ダ列タ系連用テ形
           形容詞：＊：ナノ形容詞：ダ列基本推量形
           形容詞：＊：ナノ形容詞：ダ列基本連体形
           形容詞：＊：ナノ形容詞：ダ列基本連用形
           形容詞：＊：ナノ形容詞：ダ列特殊連体形
           形容詞：＊：ナノ形容詞：基本形
           形容詞：＊：ナノ形容詞：語幹
           形容詞：＊：ナ形容詞：ダ列タ系連用テ形
           形容詞：＊：ナ形容詞：ダ列基本連体形
           形容詞：＊：ナ形容詞：ダ列基本連用形
           形容詞：＊：ナ形容詞：デス列基本形
           形容詞：＊：ナ形容詞：デス列基本推量形
           形容詞：＊：ナ形容詞：基本形
           形容詞：＊：ナ形容詞：語幹
           形容詞：＊：ナ形容詞特殊：ダ列基本連体形
           形容詞：＊：ナ形容詞特殊：ダ列特殊連体形
           形容詞：＊：ナ形容詞特殊：基本形
           形容詞：＊：ナ形容詞特殊：語幹
           指示詞：副詞形態指示詞：＊：＊
           指示詞：名詞形態指示詞：＊：＊
           指示詞：連体詞形態指示詞：＊：＊
           助詞：格助詞：＊：＊
           助詞：終助詞：＊：＊
           助詞：接続助詞：＊：＊
           助詞：副助詞：＊：＊
           助動詞：＊：イ形容詞イ段：基本形
           助動詞：＊：イ形容詞イ段：基本連用形
           助動詞：＊：ナノ形容詞：ダ列タ系連用テ形
           助動詞：＊：ナノ形容詞：ダ列基本連用形
           助動詞：＊：ナノ形容詞：ダ列特殊連体形
           助動詞：＊：ナノ形容詞：基本形
           助動詞：＊：ナノ形容詞：語幹
           助動詞：＊：ナ形容詞：ダ列タ形
           助動詞：＊：ナ形容詞：ダ列タ系連用ジャ形
           助動詞：＊：ナ形容詞：ダ列タ系連用テ形
           助動詞：＊：ナ形容詞：ダ列基本推量形
           助動詞：＊：ナ形容詞：ダ列基本連体形
           助動詞：＊：ナ形容詞：ダ列基本連用形
           助動詞：＊：ナ形容詞：デアル列タ系連用テ形
           助動詞：＊：ナ形容詞：デアル列基本形
           助動詞：＊：ナ形容詞：デアル列基本推量形
           助動詞：＊：ナ形容詞：デス列基本形
           助動詞：＊：ナ形容詞：デス列基本推量形
           助動詞：＊：ナ形容詞：基本形
           助動詞：＊：ナ形容詞：語幹
           助動詞：＊：助動詞く型：基本形
           助動詞：＊：助動詞く型：基本連用形
           助動詞：＊：助動詞く型：文語連体形
           助動詞：＊：助動詞そうだ型：デス列基本形
           助動詞：＊：助動詞そうだ型：基本形
           助動詞：＊：助動詞だろう型：ダ列基本条件形
           助動詞：＊：助動詞だろう型：デス列基本推量形
           助動詞：＊：助動詞だろう型：基本形
           助動詞：＊：助動詞ぬ型：タ系連用テ形
           助動詞：＊：助動詞ぬ型：音便基本形
           助動詞：＊：助動詞ぬ型：基本形
           助動詞：＊：助動詞ぬ型：基本条件形
           助動詞：＊：助動詞ぬ型：基本連用形
           助動詞：＊：助動詞ぬ型：文語連体形
           助動詞：＊：判定詞：ダ列タ形
           助動詞：＊：判定詞：ダ列特殊連体形
           助動詞：＊：判定詞：デス列基本形
           助動詞：＊：判定詞：基本形
           助動詞：＊：無活用型：基本形
           接続詞：＊：＊：＊
           接頭辞：ナ形容詞接頭辞：＊：＊
           接頭辞：名詞接頭辞：＊：＊
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：タ形
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：タ系連用テ形
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：音便条件形２
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：基本形
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：基本条件形
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：基本推量形
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：基本連用形
           接尾辞：形容詞性述語接尾辞：イ形容詞アウオ段：語幹
           接尾辞：形容詞性述語接尾辞：ナノ形容詞：ダ列タ形
           接尾辞：形容詞性述語接尾辞：ナノ形容詞：ダ列基本連体形
           接尾辞：形容詞性述語接尾辞：ナ形容詞：ダ列タ系連用テ形
           接尾辞：形容詞性述語接尾辞：ナ形容詞：ダ列基本連体形
           接尾辞：形容詞性述語接尾辞：ナ形容詞：ダ列基本連用形
           接尾辞：形容詞性述語接尾辞：ナ形容詞：基本形
           接尾辞：形容詞性述語接尾辞：ナ形容詞：語幹
           接尾辞：形容詞性名詞接尾辞：ナ形容詞：ダ列タ系連用テ形
           接尾辞：形容詞性名詞接尾辞：ナ形容詞：ダ列基本連体形
           接尾辞：形容詞性名詞接尾辞：ナ形容詞：ダ列基本連用形
           接尾辞：形容詞性名詞接尾辞：ナ形容詞：基本形
           接尾辞：動詞性接尾辞：カ変動詞：タ形
           接尾辞：動詞性接尾辞：カ変動詞：タ系連用テ形
           接尾辞：動詞性接尾辞：カ変動詞：基本形
           接尾辞：動詞性接尾辞：カ変動詞：基本連用形
           接尾辞：動詞性接尾辞：カ変動詞：未然形
           接尾辞：動詞性接尾辞：カ変動詞来：タ形
           接尾辞：動詞性接尾辞：カ変動詞来：タ系連用テ形
           接尾辞：動詞性接尾辞：カ変動詞来：基本形
           接尾辞：動詞性接尾辞：サ変動詞：タ形
           接尾辞：動詞性接尾辞：サ変動詞：タ系連用テ形
           接尾辞：動詞性接尾辞：サ変動詞：基本形
           接尾辞：動詞性接尾辞：サ変動詞：基本連用形
           接尾辞：動詞性接尾辞：サ変動詞：未然形
           接尾辞：動詞性接尾辞：子音動詞カ行：基本形
           接尾辞：動詞性接尾辞：子音動詞カ行：基本連用形
           接尾辞：動詞性接尾辞：子音動詞カ行促音便形：タ形
           接尾辞：動詞性接尾辞：子音動詞カ行促音便形：タ系連用テ形
           接尾辞：動詞性接尾辞：子音動詞カ行促音便形：意志形
           接尾辞：動詞性接尾辞：子音動詞カ行促音便形：基本形
           接尾辞：動詞性接尾辞：子音動詞カ行促音便形：基本条件形
           接尾辞：動詞性接尾辞：子音動詞カ行促音便形：基本連用形
           接尾辞：動詞性接尾辞：子音動詞カ行促音便形：未然形
           接尾辞：動詞性接尾辞：子音動詞ラ行：タ形
           接尾辞：動詞性接尾辞：子音動詞ラ行：タ系連用タリ形
           接尾辞：動詞性接尾辞：子音動詞ラ行：タ系連用テ形
           接尾辞：動詞性接尾辞：子音動詞ラ行：基本形
           接尾辞：動詞性接尾辞：子音動詞ラ行：基本連用形
           接尾辞：動詞性接尾辞：子音動詞ラ行：未然形
           接尾辞：動詞性接尾辞：子音動詞ラ行イ形：命令形
           接尾辞：動詞性接尾辞：子音動詞ワ行：タ形
           接尾辞：動詞性接尾辞：子音動詞ワ行：タ系連用テ形
           接尾辞：動詞性接尾辞：子音動詞ワ行：基本形
           接尾辞：動詞性接尾辞：子音動詞ワ行：基本条件形
           接尾辞：動詞性接尾辞：子音動詞ワ行：基本連用形
           接尾辞：動詞性接尾辞：動詞性接尾辞ます型：タ形
           接尾辞：動詞性接尾辞：動詞性接尾辞ます型：タ系連用テ形
           接尾辞：動詞性接尾辞：動詞性接尾辞ます型：意志形
           接尾辞：動詞性接尾辞：動詞性接尾辞ます型：基本形
           接尾辞：動詞性接尾辞：動詞性接尾辞ます型：未然形
           接尾辞：動詞性接尾辞：動詞性接尾辞得る型：基本形
           接尾辞：動詞性接尾辞：母音動詞：タ形
           接尾辞：動詞性接尾辞：母音動詞：タ系条件形
           接尾辞：動詞性接尾辞：母音動詞：タ系連用タリ形
           接尾辞：動詞性接尾辞：母音動詞：タ系連用テ形
           接尾辞：動詞性接尾辞：母音動詞：意志形
           接尾辞：動詞性接尾辞：母音動詞：基本形
           接尾辞：動詞性接尾辞：母音動詞：基本条件形
           接尾辞：動詞性接尾辞：母音動詞：基本連用形
           接尾辞：動詞性接尾辞：母音動詞：未然形
           接尾辞：名詞性述語接尾辞：＊：＊
           接尾辞：名詞性特殊接尾辞：＊：＊
           接尾辞：名詞性名詞助数辞：＊：＊
           接尾辞：名詞性名詞接尾辞：＊：＊
           動詞：＊：カ変動詞：タ形
           動詞：＊：カ変動詞：基本形
           動詞：＊：カ変動詞来：タ形
           動詞：＊：カ変動詞来：タ系連用テ形
           動詞：＊：カ変動詞来：基本形
           動詞：＊：カ変動詞来：基本連用形
           動詞：＊：カ変動詞来：未然形
           動詞：＊：サ変動詞：タ形
           動詞：＊：サ変動詞：タ系条件形
           動詞：＊：サ変動詞：タ系連用タリ形
           動詞：＊：サ変動詞：タ系連用テ形
           動詞：＊：サ変動詞：意志形
           動詞：＊：サ変動詞：基本形
           動詞：＊：サ変動詞：基本条件形
           動詞：＊：サ変動詞：基本連用形
           動詞：＊：サ変動詞：文語基本形
           動詞：＊：サ変動詞：文語未然形
           動詞：＊：サ変動詞：文語命令形
           動詞：＊：サ変動詞：未然形
           動詞：＊：ザ変動詞：タ形
           動詞：＊：ザ変動詞：タ系連用テ形
           動詞：＊：ザ変動詞：基本連用形
           動詞：＊：子音動詞カ行：タ形
           動詞：＊：子音動詞カ行：タ系条件形
           動詞：＊：子音動詞カ行：タ系連用テ形
           動詞：＊：子音動詞カ行：意志形
           動詞：＊：子音動詞カ行：基本形
           動詞：＊：子音動詞カ行：基本条件形
           動詞：＊：子音動詞カ行：基本連用形
           動詞：＊：子音動詞カ行：未然形
           動詞：＊：子音動詞カ行：命令形
           動詞：＊：子音動詞カ行促音便形：意志形
           動詞：＊：子音動詞カ行促音便形：基本形
           動詞：＊：子音動詞カ行促音便形：基本条件形
           動詞：＊：子音動詞カ行促音便形：基本連用形
           動詞：＊：子音動詞カ行促音便形：未然形
           動詞：＊：子音動詞ガ行：タ形
           動詞：＊：子音動詞ガ行：タ系連用テ形
           動詞：＊：子音動詞ガ行：基本形
           動詞：＊：子音動詞ガ行：基本連用形
           動詞：＊：子音動詞ガ行：未然形
           動詞：＊：子音動詞サ行：タ形
           動詞：＊：子音動詞サ行：タ系連用テ形
           動詞：＊：子音動詞サ行：基本形
           動詞：＊：子音動詞サ行：基本条件形
           動詞：＊：子音動詞サ行：基本連用形
           動詞：＊：子音動詞サ行：語幹
           動詞：＊：子音動詞サ行：未然形
           動詞：＊：子音動詞サ行：命令形
           動詞：＊：子音動詞タ行：タ形
           動詞：＊：子音動詞タ行：タ系連用テ形
           動詞：＊：子音動詞タ行：基本形
           動詞：＊：子音動詞タ行：基本条件形
           動詞：＊：子音動詞タ行：基本連用形
           動詞：＊：子音動詞タ行：未然形
           動詞：＊：子音動詞ナ行：タ形
           動詞：＊：子音動詞ナ行：タ系連用テ形
           動詞：＊：子音動詞ナ行：基本形
           動詞：＊：子音動詞バ行：タ形
           動詞：＊：子音動詞バ行：タ系連用テ形
           動詞：＊：子音動詞バ行：基本形
           動詞：＊：子音動詞バ行：基本連用形
           動詞：＊：子音動詞バ行：未然形
           動詞：＊：子音動詞マ行：タ形
           動詞：＊：子音動詞マ行：タ系連用テ形
           動詞：＊：子音動詞マ行：意志形
           動詞：＊：子音動詞マ行：基本形
           動詞：＊：子音動詞マ行：基本連用形
           動詞：＊：子音動詞マ行：未然形
           動詞：＊：子音動詞ラ行：タ形
           動詞：＊：子音動詞ラ行：タ系条件形
           動詞：＊：子音動詞ラ行：タ系連用タリ形
           動詞：＊：子音動詞ラ行：タ系連用テ形
           動詞：＊：子音動詞ラ行：意志形
           動詞：＊：子音動詞ラ行：基本形
           動詞：＊：子音動詞ラ行：基本条件形
           動詞：＊：子音動詞ラ行：基本連用形
           動詞：＊：子音動詞ラ行：語幹
           動詞：＊：子音動詞ラ行：未然形
           動詞：＊：子音動詞ラ行イ形：命令形
           動詞：＊：子音動詞ワ行：タ形
           動詞：＊：子音動詞ワ行：タ系連用テ形
           動詞：＊：子音動詞ワ行：基本形
           動詞：＊：子音動詞ワ行：基本条件形
           動詞：＊：子音動詞ワ行：基本連用形
           動詞：＊：子音動詞ワ行：未然形
           動詞：＊：子音動詞ワ行：命令形
           動詞：＊：子音動詞ワ行文語音便形：基本形
           動詞：＊：子音動詞ワ行文語音便形：未然形
           動詞：＊：動詞性接尾辞ます型：タ形
           動詞：＊：動詞性接尾辞ます型：基本形
           動詞：＊：動詞性接尾辞ます型：未然形
           動詞：＊：母音動詞：タ形
           動詞：＊：母音動詞：タ系連用テ形
           動詞：＊：母音動詞：意志形
           動詞：＊：母音動詞：基本形
           動詞：＊：母音動詞：基本条件形
           動詞：＊：母音動詞：基本連用形
           動詞：＊：母音動詞：語幹
           動詞：＊：母音動詞：未然形
           特殊：括弧始：＊：＊
           特殊：括弧終：＊：＊
           特殊：記号：＊：＊
           特殊：句点：＊：＊
           特殊：読点：＊：＊
           判定詞：＊：判定詞：ダ列タ形
           判定詞：＊：判定詞：ダ列タ系条件形
           判定詞：＊：判定詞：ダ列タ系連用ジャ形
           判定詞：＊：判定詞：ダ列タ系連用タリ形
           判定詞：＊：判定詞：ダ列タ系連用テ形
           判定詞：＊：判定詞：ダ列基本推量形
           判定詞：＊：判定詞：ダ列基本連体形
           判定詞：＊：判定詞：ダ列特殊連体形
           判定詞：＊：判定詞：デアル列タ形
           判定詞：＊：判定詞：デアル列タ系連用テ形
           判定詞：＊：判定詞：デアル列基本形
           判定詞：＊：判定詞：デアル列基本推量形
           判定詞：＊：判定詞：デアル列基本連用形
           判定詞：＊：判定詞：デス列タ形
           判定詞：＊：判定詞：デス列基本形
           判定詞：＊：判定詞：デス列基本推量形
           判定詞：＊：判定詞：基本形
           範疇外：＊：＊：＊
           副詞：＊：＊：＊
           名詞：サ変名詞：＊：＊
           名詞：形式名詞：＊：＊
           名詞：固有名詞：＊：＊
           名詞：時相名詞：＊：＊
           名詞：数詞：＊：＊
           名詞：普通名詞：＊：＊
           名詞：副詞的名詞：＊：＊
           連体詞：＊：＊：＊);

@PartCode = map(sprintf("%04d", $_), (0 .. $#Part));

%Part = map(($Part[$_] => $_), (0..$#Part));

@UTPart = map($UT . $_, @Part);
@Tokens = ($UT, $BT, @Part);


#=====================================================================================
#                        END
#=====================================================================================
