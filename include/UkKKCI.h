//====================================================================================
//                       UkKKCI.h
//                            by Shinsuke MORI
//                            Last change : 18 May 1996
//====================================================================================

// 機  能 : 文字 2-gram による未知語モデル
//
// 注意点 : 未知文字モデルのファイルが KKCI... に格納されていること
//          アクセスされる長さにかかわらず maxlen 文字のテーブルを確保


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

           U_INT4   curpos;                       // 現在の位置(文頭からの文字数)

           U_INT4   maxlen;                       // 長さの最大値

           U_INT4   wc2int[0x10000];        // 各品詞の文字から状態への写像

           U_INT4   curr;                   // 各品詞の今の状態

           Markov   markov;                 // 各品詞の文字マルコフモデル

           DECIM8_P LogP;                   // 各品詞の各位置での対数確率

           DECIM8   UTlogP;                 // 各品詞の -log(P(Σ|UT))

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
    S_CHAR buff[4];                               // ファイル読み込みのためのバッファ
    for (lineno = 0; file.read(buff, 3); lineno++){
        assert(buff[2] == '\n');                  // 一つの全角文字と改行コードのはず
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
