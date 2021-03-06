//====================================================================================
//                       InMorp.h
//                            by Shinsuke MORI
//                            Last change : 15 November 1995
//====================================================================================

// 機  能 : 内部辞書の形態素
//
// 注意点 : ほとんど構造体
//          いずれは継承に変更

#ifndef _InMorp_h
#define _InMorp_h 1


//------------------------------------------------------------------------------------
//                       class InMorp
//------------------------------------------------------------------------------------

class InMorp;
typedef InMorp* InMorp_P;

class InMorp{

  private:

  public:

    U_INT4 length;                                // 文字数

    U_INT4 stat;				  // 状態番号 (cf. WordIntStr.text)

    DECIM8 logP;		                  // 負対数確率

           InMorp(U_INT4, U_INT4, DECIM8);

    void   fprint(ostream&);                      // インスタンスの表示

};


//------------------------------------------------------------------------------------
//                       InMorp
//------------------------------------------------------------------------------------

InMorp::InMorp(U_INT4 length = 0, U_INT4 stat = 0, DECIM8 logP = 0)
: length(length), stat(stat), logP(logP)
{
    ;                                             // No Operation
}


//------------------------------------------------------------------------------------
//                       fprint
//------------------------------------------------------------------------------------

void InMorp::fprint(ostream& fout = cout)
{
    fout << "(" << length << ", " << stat << ", " << logP << ")" << endl;
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
