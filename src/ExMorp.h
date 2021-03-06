//====================================================================================
//                       ExMorp.h
//                            by Shinsuke MORI
//                            Last change : 1 November 1995
//====================================================================================

#ifndef _ExMorp_h
#define _ExMorp_h

#include "mystd.h"


//------------------------------------------------------------------------------------
//                       class ExMorp
//------------------------------------------------------------------------------------

class ExMorp;
typedef ExMorp* ExMorp_P;

class ExMorp{

  private:

  public:

    U_INT4 length;                                // ʸ����

    U_INT4 text;		                  // �Ѵ�����ɽ��

    DECIM8 logP;                                  // ������Ψ�����п���

    ExMorp(U_INT4 length = 0, U_INT4 text = 0, DECIM8 logP = 0.0)
    : length(length), text(text), logP(logP)
    {
        ;                                             // No Operation
    }

    void   fprint(ostream&);                      // ���󥹥��󥹤�ɽ��

};


//------------------------------------------------------------------------------------
//                       ExMorp
//------------------------------------------------------------------------------------

// ExMorp::ExMorp(U_INT4 length = 0, U_INT4 text = 0, DECIM8 logP = 0.0)
// : length(length), text(text), logP(logP)
// {
//     ;                                             // No Operation
// }


//------------------------------------------------------------------------------------
//                       fprint
//------------------------------------------------------------------------------------

void ExMorp::fprint(ostream& fout = cout)
{
    fout << "(" << length << ", " << text << ", " << logP << ")" << endl;
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
