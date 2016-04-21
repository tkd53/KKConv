//====================================================================================
//                       UkYomi.h
//                            by Shinsuke MORI
//                            Last change : 18 May 1996
//====================================================================================

// 機  能 : 文字 2-gram による未知語モデル
//
// 注意点 : 未知文字モデルのファイルが Yomi... に格納されていること
//          アクセスされる長さにかかわらず maxlen 文字のテーブルを確保


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

           U_INT4   curpos;                 // 現在の位置(文頭からの文字数)

           U_INT4   maxlen;                 // 長さの最大値

           U_INT4   wc2int[0x10000];        // 文字から状態への写像

           U_INT4   curr;                   // 今の状態

           Markov   markov;                 // 文字マルコフモデル

           DECIM8_P LogP;                   // 各位置での対数確率

           DECIM8   UTlogP;                 // -log(P(Σ|UT))

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
    S_CHAR buff[4];                               // ファイル読み込みのためのバッファ
    for (lineno = 0; file.read(buff, 3); lineno++){
        assert(buff[2] == '\n');                  // 一つの全角文字と改行コードのはず
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

    U_INT4 next = wc2int[code.full];              // 次の状態
    for (U_INT4 i = 0; i < curpos; i++){
        LogP[i] += markov.logP(curr, next);
        if (next == UT){                          // 未知文字の場合
            LogP[i] += UTlogP;
        }
    }
    LogP[curpos] = markov.logP(BT, next);
    if (next == UT){                              // 未知文字の場合
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
