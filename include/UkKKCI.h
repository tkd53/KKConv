//====================================================================================
//                       UkKKCI.h
//                            by Shinsuke MORI
//                            Last change : 18 May 1996
//====================================================================================

// ��  ǽ : ʸ�� 2-gram �ˤ��̤�θ��ǥ�
//
// ����� : ̤��ʸ����ǥ�Υե����뤬 KKCI... �˳�Ǽ����Ƥ��뤳��
//          �������������Ĺ���ˤ�����餺 maxlen ʸ���Υơ��֥�����


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _UkKKCI_h
#define _UkKKCI_h

#ifdef DEBUG
#define UkKKCI_DEBUG
#endif
//#define UkKKCI_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <mystd.h>
#include <W_CHAR.h>
#include <Markov.h>


//------------------------------------------------------------------------------------
//                       class UkKKCI
//------------------------------------------------------------------------------------

class UkKKCI
{

  public:

                    UkKKCI(U_INT4);
    
           void     init();
    
           void     tran(W_CHAR);

    inline DECIM8   logP(U_INT4) const;

    inline DECIM8   prob(U_INT4) const;

#ifdef COST
    inline U_INT4   cost(U_INT4) const;
#endif // COST

  private:

           U_INT4   curpos;                       // ���ߤΰ���(ʸƬ�����ʸ����)

           U_INT4   maxlen;                       // Ĺ���κ�����

           U_INT4   wc2int[0x10000];        // ���ʻ��ʸ��������֤ؤμ���

           U_INT4   curr;                   // ���ʻ�κ��ξ���

           Markov   markov;                 // ���ʻ��ʸ���ޥ륳�ե�ǥ�

           DECIM8_P LogP;                   // ���ʻ�γư��֤Ǥ��п���Ψ

           DECIM8   UTlogP;                 // ���ʻ�� -log(P(��|UT))

};

    
//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

UkKKCI::UkKKCI(U_INT4 maxlen)
: curpos(0), maxlen(maxlen)
{
#ifdef UkKKCI_DEBUG
    cerr << "UkKKCI::UkKKCI(U_INT4)" << endl;
#endif

    curr = BT;
        
    markov.dbbind("KKCIMarkov");
    markov.setlambda("KKCILambda");

    LogP = new DECIM8[maxlen];

    for (U_INT4 full = 0; full < 0x10000; full++) wc2int[full] = 0;

    U_INT4 lineno;
    ifstream file("KKCIIntStr.text");
    if (! file) openfailed("KKCIIntStr.text");
    S_CHAR buff[4];                               // �ե������ɤ߹��ߤΤ���ΥХåե�
    for (lineno = 0; file.read(buff, 3); lineno++){
        assert(buff[2] == '\n');                  // ��Ĥ�����ʸ���Ȳ��ԥ����ɤΤϤ�
        W_CHAR wc(buff);
        wc2int[wc.full] = lineno;
    }
    file.close();
    UTlogP = log(YomiAlphabetSize-(lineno-2));    // ??
}
        
    
//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

inline void UkKKCI::init()
{
#ifdef UkKKCI_DEBUG
    cerr << "UkKKCI::init()" << endl;
#endif

    curr = BT;
    curpos = 0;
}


//------------------------------------------------------------------------------------
//                       tran
//------------------------------------------------------------------------------------

inline void UkKKCI::tran(const W_CHAR code)
{
#ifdef UkKKCI_DEBUG
    cerr << "UkKKCI::tran(const W_CHAR)" << endl;
#endif

    U_INT4 next = wc2int[code.full];              // ���ξ���
    for (U_INT4 i = 0; i < curpos; i++){
        LogP[i] += markov.logP(curr, next);
        if (next == UT){                          // ̤��ʸ���ξ��
            LogP[i] += UTlogP;
        }
    }
    LogP[curpos] = markov.logP(BT, next);
    if (next == UT){                              // ̤��ʸ���ξ��
        LogP[curpos] += UTlogP;
    }
    curr = next;

    curpos++;
}


//------------------------------------------------------------------------------------
//                       logP
//------------------------------------------------------------------------------------

inline DECIM8 UkKKCI::logP(U_INT4 length) const
{
#ifdef UkKKCI_DEBUG
    cerr << "UkKKCI::logP(U_INT4)" << endl;
#endif

    return(LogP[curpos-length]+markov.logP(curr, BT));
}


//------------------------------------------------------------------------------------
//                       prob
//------------------------------------------------------------------------------------

inline DECIM8 UkKKCI::prob(U_INT4 length) const
{
#ifdef UkKKCI_DEBUG
    cerr << "UkKKCI::logP(U_INT4)" << endl;
#endif

    return(exp(-logP(length)));
}


//------------------------------------------------------------------------------------
//                       cost
//------------------------------------------------------------------------------------

#ifdef COST

inline U_INT4 UkKKCI::cost(U_INT4 length) const
{
#ifdef UkKKCI_DEBUG
    cerr << "UkKKCI::cost(U_INT4)" << endl;
#endif

    return(U_INT4(mult*logP(length)));
}

#endif // COST


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
