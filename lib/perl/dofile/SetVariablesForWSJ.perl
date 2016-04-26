use bytes;
#=====================================================================================
#                        SetVariablesForWSJ.perl
#                             by Shinsuke Mori
#                             Last change : 14 May 2008
#=====================================================================================

# ��  ǽ : Wall Street Journal (Penn Treebank) �����ѥ��Τ������������
#
# ��  �� : �ʤ�


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

$CTEMPL = "../../../corpus/WSJ%02d.morphs";          # �����ѥ��Υե�����̾�������ο���

@Part     = qw(�ӣ٣�     �ΣΣУ�   �ã�       �ã�       �ơ�       �ǡ�
               �ͣ�       �ң�       �ʣ�       �ɣ�       �ףС�     �ģ�
               �֣�       �Σ�       �գ�       �ƣ�       �ţ�       �̣�
               �ݣ̣ң¡� ��         �֣£�     ��         �ң�       �֣£�
               ��         �ԣ�       �ݣңң¡� �УңС�   �ף�       �ң£�
               �֣£�     �ʣʣ�     �ң£�     �ʣʣ�     �Уģ�     �֣£�
               ��         �ףң�     ��         �ΣΣ�     �ףģ�     �ΣΣ�
               �֣£�     �Уң�     �Уϣ�);
@PartCode = qw(SYMx       NNPS       CCxx       CDxx       LODQ       RCDQ
               MDxx       RBxx       JJxx       INxx       WPpx       DTxx
               VBxx       NNxx       UHxx       FWxx       EXxx       LSxx
               LRB-       Comm       VBDx       Peri       RPxx       VBGx
               Colo       TOxx       RRB-       PRPp       WPxx       RBRx
               VBNx       JJRx       RBSx       JJSx       PDTx       VBPx
               Doll       WRBx       Poun       NNPx       WDTx       NNSx
               VBZx       PRPx       POSx);

%Part = map(($Part[$_] => $_), (0..$#Part));
%PartCode = map(($PartCode[$_] => $_), (0..$#PartCode));

@UTPart = map($UT . $_, @Part);
@Tokens = ($UT, $BT, @Part);

@MorpMarkovTest = ("�ԣ��/�ģ�", "����/�ʣ�", "�Σ�", "�Σ�");
@CharMarkovTest = ($BT, "��");


#=====================================================================================
#                        END
#=====================================================================================
