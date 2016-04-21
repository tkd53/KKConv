//====================================================================================
//                       ExMorp.h
//                            by Shinsuke MORI
//                            Last change : 1 November 1995
//====================================================================================

// ��  ǽ : ��������η�����
//
// ������ : �ۤȤ�ɹ�¤��


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

#ifdef PART
    U_INT4 part;                                  // ����
#endif

    U_INT4 length;                                // ʸ����

    DECIM8 logP;                                  // ������Ψ�����п���

#ifdef PART
           ExMorp(U_INT4, U_INT4, DECIM8);
#else
           ExMorp(U_INT4, DECIM8);
#endif

#ifdef COST
    U_INT4 cost();                                // ������Ψ�Υ�����
#endif // COST

    void   fprint(ostream&);                      // ���󥹥��󥹤�ɽ��

  private:

};


//------------------------------------------------------------------------------------
//                       ExMorp
//------------------------------------------------------------------------------------

#ifdef PART
ExMorp::ExMorp(U_INT4 part = 0, U_INT4 length = 0, DECIM8 logP = DECIM8(0))
: part(part), length(length), logP(logP)
#else
ExMorp::ExMorp(U_INT4 length = 0, DECIM8 logP = DECIM8(0))
: length(length), logP(logP)
#endif
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
#ifdef PART
    fout << "(" << part << ", " << length << ", " << logP << ")" << endl;
#else
    fout << "(" << length << ", " << logP << ")" << endl;
#endif
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================