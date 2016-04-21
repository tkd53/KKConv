//====================================================================================
//                       ExMorp.h
//                            by Shinsuke MORI
//                            Last change : 1 November 1995
//====================================================================================

// 機  能 : 外部辞書の形態素
//
// 注意点 : ほとんど構造体


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _ExMorp_h
#define _ExMorp_h


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <mystd.h>


//------------------------------------------------------------------------------------
//                       class ExMorp
//------------------------------------------------------------------------------------

class ExMorp;
typedef ExMorp* ExMorp_P;

class ExMorp{

  public:

    U_INT4 part;                                  // 状態

    U_INT4 length;                                // 文字数

    DECIM8 logP;                                  // 生成確率の負対数値

           ExMorp(U_INT4, U_INT4, DECIM8);

#ifdef COST
    U_INT4 cost();                                // 生成確率のコスト
#endif // COST

    void   fprint(ostream&);                      // インスタンスの表示

  private:

};


//------------------------------------------------------------------------------------
//                       ExMorp
//------------------------------------------------------------------------------------

ExMorp::ExMorp(U_INT4 part = 0, U_INT4 length = 0, DECIM8 logP = DECIM8(0))
: part(part), length(length), logP(logP)
{
    ;
}


//------------------------------------------------------------------------------------
//                       cost
//------------------------------------------------------------------------------------

#ifdef COST

U_INT4 ExMorp::cost()
{
    return(U_INT4(mult*logP));
}

#endif // COST


//------------------------------------------------------------------------------------
//                       fprint
//------------------------------------------------------------------------------------

void ExMorp::fprint(ostream& fout = cout)
{
    fout << "(" << part << ", " << length << ", " << logP << ")" << endl;
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
