//====================================================================================
//                       KKConv.h
//                            by Shinsuke MORI
//                            Last change : 24 April 1996
//====================================================================================

// ��  ǽ : �����ץ����Ȥ��̿��Τ���ΥХåե���
//
// ����� : cf. src-util/agent.c struct connection


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _KKConv_h
#define _KKConv_h

#ifdef DEBUG
#define KKConv_DEBUG
#endif
//#define KKConv_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <math.h>
#include <mystd.h>
#include <minmax.h>

#include "UkWord.h"
#include "UkKKCI.h"
#include "Markov.h"
#include "IntStr.h"
#include "InMorp.h"
#include "ExDict.h"
#include "ExMorp.h"
#include "ServerVTable.h"


//------------------------------------------------------------------------------------
//                       class KKConv
//------------------------------------------------------------------------------------

class KKConv{

  public:

           KKConv(const string&);

    void   init();

    void   tran(const W_CHAR&);

    string conv(W_String&);

    string conv(W_String&, U_INT4);

    string list(W_String&);

    string list(W_String&, const string&);

friend ostream& operator<<(ostream&, const KKConv&);

friend istream& operator>>(istream&, KKConv&);

  private:

    IntStr intstr;                                // �ʻ��ֹ椫���ʻ�ɽ���ؤα���

    Markov markov;                                // �������Υޥ륳�ե�ǥ�

    InDict indict;

    UkWord ukword;                        // ̤�θ��ǥ� P(x)

//    UkKKCI ukkkci;                        // ̤�����ϥ�ǥ� P(y)

    ExDict tkdict;                                // ñ��������

    IntStr tktext;                                // ñ��������

    VTable vtable;

    void   dict(const U_INT4&);

};


//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

inline KKConv::KKConv(const string& stem)
//: intstr(stem + "WordIntStr"), markov(stem + "WordMarkov"), indict(stem + "InDict"),
: intstr(stem + "InDict"), markov(stem + "WordMarkov"), indict(stem + "InDict"),
  ukword(MAXLEN, stem), tkdict(stem + "Tankan"), tktext(stem + "Tankan"), 
  vtable(intstr, markov, ukword, MAXLEN)
{
    ;                                             // NOP
    cerr << "Initialize Done" << endl;
}


//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

inline void KKConv::init()
{
    //    ukkkci.init();
    ukword.init();
    indict.init();

    vtable.init();
}


//------------------------------------------------------------------------------------
//                       tran
//------------------------------------------------------------------------------------

inline void KKConv::tran(const W_CHAR& wc)
{
//    ukkkci.tran(wc);
    ukword.tran(wc);
    indict.tran(wc);
}


//------------------------------------------------------------------------------------
//                       conv
//------------------------------------------------------------------------------------

// ��  ǽ : ����ʸ������Ѵ�
//
// ����ˡ : conv("���󤸤Ǥ���")

string KKConv::conv(W_String& senten)
{
    init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // ���Ϥ�ɽ��
#endif // KKConv_DEBUG

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // ����ʤɤξ�������
#ifdef KKConv_DEBUG
//        dictin(indict, intstr, curpos, senten);
//        taskdict(taskindict, taskintstr, curpos, senten);
#endif // KKConv_DEBUG
//        vtable.fill(indict, taskindict, ukkkci);
        vtable.fill(indict, ukword);
    }

//    vtable.output(senten, intstr, taskintstr);

    return(vtable.output(senten));
}


//------------------------------------------------------------------------------------

// ��  ǽ : �ǽ��ñ�춭������ꤷ�Ƥ�����ʸ������Ѵ�
//
// ����ˡ : conv("���󤸤Ǥ���", 3) // ��ʸ���ܤ�ľ��˶����������Τ�õ��
//
// ����� : �ʤ�

string KKConv::conv(W_String& senten, U_INT4 fb)
{
    init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
    if (senten.length() < fb) exit(-1);           // �����λ��꤬�ϰ��⤫

#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // ���Ϥ�ɽ��
#endif // KKConv_DEBUG
    cerr << senten << endl;                       // ���Ϥ�ɽ��

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // ����ʤɤξ�������
#ifdef KKConv_DEBUG
//        dictin(indict, intstr, curpos, senten);
//        taskdict(taskindict, taskintstr, curpos, senten);
#endif // KKConv_DEBUG
//        vtable.fill(indict, taskindict, ukkkci);
        vtable.fill(indict, ukword, fb);
    }

    return(vtable.output(senten));
}


//------------------------------------------------------------------------------------
//                       list
//------------------------------------------------------------------------------------

// ��  ǽ : ����ʸ������Ѵ���������
//
// ����ˡ : list("����")
//
// ����� : �ʤ�

string KKConv::list(W_String& senten)
{
    init();
    tkdict.init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // ���Ϥ�ɽ��
#endif // KKConv_DEBUG

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // ����ʤɤξ�������
        tkdict.tran(senten[curpos]);

#ifdef KKConv_DEBUG
//        dictin(indict, intstr, curpos, senten);
//        taskdict(taskindict, taskintstr, curpos, senten);
#endif // KKConv_DEBUG
//        vtable.fill(indict, taskindict, ukkkci);
//        vtable.fill(indict, taskindict, ukword);
    }

    typedef pair<DECIM8, string[2]> PAIR;         // (logP, (word, ORIG))
    typedef multimap<DECIM8, string[2]> MMap;     // logP => PAIR+

    MMap mmap;                                    // (��Ψ, ñ��) �ν���դ��ꥹ��
    bool flag = FAUX;                             // ʿ��̾�Τߤ���ʤ�ñ�줬���뤫
    for (InMorp_P morp = indict.lenpos(); morp->length > 0; morp++){
        if (morp->length != senten.length()) continue; // Ĺ�������ʤ������̵��
        DECIM8 prob = markov._1prob(morp->stat);
        DECIM8 logP = morp->logP-log(prob);
        string temp[2] = {intstr[morp->stat], "IN"};
        mmap.insert(PAIR(logP, temp));

        W_String tempword(intstr[morp->stat]);
        if (tempword == senten) flag = VRAI;
    }

/* ñ���������Ȥ���
    for (ExMorp_P morp = tkdict.lenpos(); morp->length > 0; morp++){
        if (morp->length != senten.length()) continue; // Ĺ�������ʤ������̵��
        DECIM8 logP = morp->logP;
        string temp[2] = {tktext[morp->text], "TK"};
        mmap.insert(PAIR(logP, temp));

        W_String tempword(tktext[morp->text]);
        if (tempword == senten) flag = VRAI;      // ʿ��̾�Τߤ���ʤ�ñ��
    }
*/
/*
    if (flag == FAUX){                            // ʿ��̾�Τߤ���ʤ�ñ�줬�ʤ����
        WORD word = STR2WORD(senten, 0, senten.length());
        DECIM8 prob = markov._1prob(UT);
        DECIM8 logP = -log(ukword.prob(word))-log(prob);
        string temp[2] = {string(S_CHAR_P(senten)), "UM"};
        mmap.insert(PAIR(logP, temp));
    }
*/
    string result = "(";
    for (MMap::iterator iter = mmap.begin(); iter != mmap.end(); iter++){
//        cerr.precision(5);
//        cerr << (*iter).first << " " << (*iter).second << endl;
        result += "(" + stringprintf("%5.2f", (*iter).first) + " ";
        result += (*iter).second[0] + " " + (*iter).second[1] + ")";
    }
    result += ")";

//    vtable.output(senten, intstr, taskintstr);

    return(result);
}


//------------------------------------------------------------------------------------

// ��  ǽ : ����ʸ������Ѵ���������
//
// ����ˡ : list("����")
//
// ����� : �ʤ�

string KKConv::list(W_String& senten, const string& word)
{
    cerr << "KKConv::list(" << senten << ", " << word << ")" << endl;
    cerr << "Not Implemented!!" << endl;
    return("NULL");

    init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // ���Ϥ�ɽ��
#endif // KKConv_DEBUG

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // ����ʤɤξ�������
#ifdef KKConv_DEBUG
//        dictin(indict, intstr, curpos, senten);
//        taskdict(taskindict, taskintstr, curpos, senten);
#endif // KKConv_DEBUG
//        vtable.fill(indict, taskindict, ukkkci);
//        vtable.fill(indict, taskindict, ukword);
    }

    typedef pair<DECIM8, string> PAIR;            // (logP, word)
    typedef multimap<DECIM8, string> MMap;        // logP => word+

    MMap mmap;                                    // (��Ψ, ñ��) �ν���դ��ꥹ��
    for (InMorp_P morp = indict.lenpos(); morp->length > 0; morp++){
        if (morp->length != senten.length()) continue; // Ĺ�������ʤ������̵��
        DECIM8 prob = markov._1prob(morp->stat);
        DECIM8 logP = morp->logP-log(prob);
        mmap.insert(PAIR(logP, intstr[morp->stat]));
    }

    string result = "";
    for (MMap::iterator iter = mmap.begin(); iter != mmap.end(); iter++){
//        cerr.precision(5);
//        cerr << (*iter).first << " " << (*iter).second << endl;
        result += (*iter).second + " ";
    }

//    vtable.output(senten, intstr, taskintstr);

    return(result);
}


//------------------------------------------------------------------------------------
//                       dict
//------------------------------------------------------------------------------------

void KKConv::dict(const U_INT4& curpos)
{
    /*
    for (InMorp_P morp = indict.lenpos() ;morp->length > 0; morp++){
        for (U_INT2 pos = 0; pos+morp->length <= curpos; pos++) cerr << "  ";
        cerr.write((S_CHAR_P)(senten+curpos+1-morp->length), morp->length*2) << "/";
        cerr << intstr[morp->stat] << "/IN " << morp->logP << endl;
    }
    for (InMorp_P morp = taskindict.lenpos(); morp->length > 0; morp++){
        for (U_INT2 pos = 0; pos+morp->length <= curpos; pos++) cerr << "  ";
        cerr.write((S_CHAR_P)(senten+curpos+1-morp->length), morp->length*2) << "/";
        cerr << taskintstr[morp->stat] << "/TI " << morp->logP << endl;
    }
    */
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
