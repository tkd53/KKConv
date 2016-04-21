//====================================================================================
//                       UkYomi.h
//                            by Shinsuke MORI
//                            Last change : 18 May 1996
//====================================================================================

// ��  ǽ : ʸ�� 2-gram �ˤ��̤�θ��ǥ�
//
// ����� : ̤��ʸ����ǥ�Υե����뤬 Yomi... �˳�Ǽ����Ƥ��뤳��
//          �������������Ĺ���ˤ�����餺 maxlen ʸ���Υơ��֥�����


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _UkYomi_h
#define _UkYomi_h

#ifdef DEBUG
#define UkYomi_DEBUG
#endif
//#define UkYomi_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <mystd.h>
#include <W_CHAR.h>
#include <Markov.h>


//------------------------------------------------------------------------------------
//                       class UkYomi
//------------------------------------------------------------------------------------

class UkYomi
{

  public:

                    UkYomi(U_INT4);

           void     init();

           void     tran(W_CHAR);

    inline DECIM8   logP(U_INT4) const;

    inline DECIM8   prob(U_INT4) const;

#ifdef COST
    inline U_INT4   cost(U_INT4) const;
#endif // COST

  private:

           U_INT4   curpos;                 // ���ߤΰ���(ʸƬ�����ʸ����)

           U_INT4   maxlen;                 // Ĺ���κ�����

           U_INT4   wc2int[0x10000];        // ʸ��������֤ؤμ���

           U_INT4   curr;                   // ���ξ���

           Markov   markov;                 // ʸ���ޥ륳�ե�ǥ�

           DECIM8_P LogP;                   // �ư��֤Ǥ��п���Ψ

           DECIM8   UTlogP;                 // -log(P(��|UT))

};


//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

UkYomi::UkYomi(U_INT4 maxlen)
: curpos(0), maxlen(maxlen)
{
#ifdef UkYomi_DEBUG
    cerr << "UkYomi::UkYomi(U_INT4)" << endl;
#endif

    curr = BT;

//    string stem = "KKCI";
    std::string tkd53home = TKD53HOME;
    string stem = tkd53home + "/dictionary/KKConv/WordKKCI-2/Step" + STEP + "/Char";

    markov.dbbind(stem + "Markov");
    markov.setlambda(stem + "Lambda");

    LogP = new DECIM8[maxlen];

    for (U_INT4 full = 0; full < 0x10000; full++) wc2int[full] = 0;

    U_INT4 lineno;
    ifstream file((stem + "IntStr.text").c_str());
    if (! file) openfailed((stem + "IntStr.text").c_str());
    S_CHAR buff[4];                               // �ե������ɤ߹��ߤΤ���ΥХåե�
    for (lineno = 0; file.read(buff, 3); lineno++){
        assert(buff[2] == '\n');                  // ��Ĥ�����ʸ���Ȳ��ԥ����ɤΤϤ�
        W_CHAR wc(buff);
        wc2int[wc.full] = lineno;
    }
    file.close();

//    assert(KKCIAlphabetSize-(lineno-2) > 0);
//    UTlogP = log(KKCIAlphabetSize-(lineno-2));
    assert(CharAlphabetSize-(lineno-2) > 0);
    UTlogP = log(CharAlphabetSize-(lineno-2));
}


//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

inline void UkYomi::init()
{
#ifdef UkYomi_DEBUG
    cerr << "UkYomi::init()" << endl;
#endif

    curr = BT;
    curpos = 0;
}


//------------------------------------------------------------------------------------
//                       tran
//------------------------------------------------------------------------------------

inline void UkYomi::tran(const W_CHAR code)
{
#ifdef UkYomi_DEBUG
    cerr << "UkYomi::tran(const W_CHAR)" << endl;
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

inline DECIM8 UkYomi::logP(U_INT4 length) const
{
#ifdef UkYomi_DEBUG
    cerr << "UkYomi::logP(U_INT4)" << endl;
#endif

    return(LogP[curpos-length]+markov.logP(curr, BT));
}


//------------------------------------------------------------------------------------
//                       prob
//------------------------------------------------------------------------------------

inline DECIM8 UkYomi::prob(U_INT4 length) const
{
#ifdef UkYomi_DEBUG
    cerr << "UkYomi::logP(U_INT4)" << endl;
#endif

    return(exp(-logP(length)));
}


//------------------------------------------------------------------------------------
//                       cost
//------------------------------------------------------------------------------------

#ifdef COST

inline U_INT4 UkYomi::cost(U_INT4 length) const
{
#ifdef UkYomi_DEBUG
    cerr << "UkYomi::cost(U_INT4)" << endl;
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
