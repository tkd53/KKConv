//====================================================================================
//                       KKConv.h
//                            by Shinsuke MORI
//                            Last change : 24 April 1996
//====================================================================================

// 機  能 : 外部プロセスとの通信のためのバッファー
//
// 注意点 : cf. src-util/agent.c struct connection


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

    IntStr intstr;                                // 品詞番号から品詞表記への応対

    Markov markov;                                // タスクのマルコフモデル

    InDict indict;

    UkWord ukword;                        // 未知語モデル P(x)

//    UkKKCI ukkkci;                        // 未知入力モデル P(y)

    ExDict tkdict;                                // 単漢字辞書

    IntStr tktext;                                // 単漢字辞書

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

// 機  能 : 入力文字列の変換
//
// 使用法 : conv("かんじでかく")

string KKConv::conv(W_String& senten)
{
    init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // 入力の表示
#endif // KKConv_DEBUG

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // 辞書などの状態遷移
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

// 機  能 : 最初の単語境界を指定しての入力文字列の変換
//
// 使用法 : conv("かんじでかく", 3) // ３文字目の直後に境界がある解のみ探索
//
// 注意点 : なし

string KKConv::conv(W_String& senten, U_INT4 fb)
{
    init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
    if (senten.length() < fb) exit(-1);           // 境界の指定が範囲内か

#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // 入力の表示
#endif // KKConv_DEBUG
    cerr << senten << endl;                       // 入力の表示

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // 辞書などの状態遷移
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

// 機  能 : 入力文字列の変換候補の列挙
//
// 使用法 : list("かんじ")
//
// 注意点 : なし

string KKConv::list(W_String& senten)
{
    init();
    tkdict.init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // 入力の表示
#endif // KKConv_DEBUG

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // 辞書などの状態遷移
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

    MMap mmap;                                    // (確率, 単語) の順序付きリスト
    bool flag = FAUX;                             // 平仮名のみからなる単語があるか
    for (InMorp_P morp = indict.lenpos(); morp->length > 0; morp++){
        if (morp->length != senten.length()) continue; // 長さが合わない候補は無視
        DECIM8 prob = markov._1prob(morp->stat);
        DECIM8 logP = morp->logP-log(prob);
        string temp[2] = {intstr[morp->stat], "IN"};
        mmap.insert(PAIR(logP, temp));

        W_String tempword(intstr[morp->stat]);
        if (tempword == senten) flag = VRAI;
    }

/* 単漢字辞書を使うか
    for (ExMorp_P morp = tkdict.lenpos(); morp->length > 0; morp++){
        if (morp->length != senten.length()) continue; // 長さが合わない候補は無視
        DECIM8 logP = morp->logP;
        string temp[2] = {tktext[morp->text], "TK"};
        mmap.insert(PAIR(logP, temp));

        W_String tempword(tktext[morp->text]);
        if (tempword == senten) flag = VRAI;      // 平仮名のみからなる単語
    }
*/
/*
    if (flag == FAUX){                            // 平仮名のみからなる単語がない場合
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

// 機  能 : 入力文字列の変換候補の列挙
//
// 使用法 : list("かんじ")
//
// 注意点 : なし

string KKConv::list(W_String& senten, const string& word)
{
    cerr << "KKConv::list(" << senten << ", " << word << ")" << endl;
    cerr << "Not Implemented!!" << endl;
    return("NULL");

    init();

    if (senten.length() > SERVERMAXLEN) exit(-1); 
#ifdef KKConv_DEBUG
    cerr << senten << endl;                       // 入力の表示
#endif // KKConv_DEBUG

    for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
        tran(senten[curpos]);                     // 辞書などの状態遷移
#ifdef KKConv_DEBUG
//        dictin(indict, intstr, curpos, senten);
//        taskdict(taskindict, taskintstr, curpos, senten);
#endif // KKConv_DEBUG
//        vtable.fill(indict, taskindict, ukkkci);
//        vtable.fill(indict, taskindict, ukword);
    }

    typedef pair<DECIM8, string> PAIR;            // (logP, word)
    typedef multimap<DECIM8, string> MMap;        // logP => word+

    MMap mmap;                                    // (確率, 単語) の順序付きリスト
    for (InMorp_P morp = indict.lenpos(); morp->length > 0; morp++){
        if (morp->length != senten.length()) continue; // 長さが合わない候補は無視
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
