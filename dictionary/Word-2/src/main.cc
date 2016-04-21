//====================================================================================
//                       main.cc
//                            by Shinsuke MORI
//                            Last change : 4 March 1995
//====================================================================================

// 機  能 : 形態素 2-gram モデルによる形態素解析器
//
// 使用法 : main < (filename)
//
// 実  例 : main < ../../corpus/NKN10.senten
//
// 注意点 : 品詞を区別する場合の特殊型(１品詞)


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#define EXDICT                                    // 外部辞書を利用する

//#define AC                                        // 辞書は AC 法
#define DA                                        // 辞書は DA 法
#define MEMORY                                    // 主記憶に載せる

//#define DEBUG

#ifdef DEBUG
#define MAIN_DEBUG
#endif
//#define MAIN_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <mystd.h>
#include <W_CHAR.h>

#include "constant.h"
#include "IntStr.h"
#include "InDict.h"
#include "ExDict.h"
#include "UkWord.h"
#include "VTable.h"
#include "Markov.h"


//------------------------------------------------------------------------------------
//                       prototypes
//------------------------------------------------------------------------------------

void usage(const S_CHAR_P);
void fordebug(const InDict&, const IntStr&, const U_INT4, const W_CHAR_P);
void fordebug(const ExDict&, const IntStr&, const U_INT4, const W_CHAR_P);


//------------------------------------------------------------------------------------
//                       main
//------------------------------------------------------------------------------------

main(S_INT4 argc, S_CHAR_P argv[])
{
    if (argc != 1) usage(argv[0]);                // 引数のチェック

    IntStr intstr("WordIntStr");                  // 品詞番号から品詞表記への応対
    Markov markov("WordMarkov", "WordLambda");    // マルコフモデル
    UkWord ukword(MAXLEN);                        // 未知語モデル
    InDict indict("InDict");                      // 内部辞書のオートマトン
#ifdef EXDICT
    ExDict exdict("ExDict");                      // 外部辞書のオートマトン
#endif // EXDICT
    VTable vtable(intstr, markov, MAXLEN);        // Viterbi Table
    cerr << "Initialize Done" << endl;

    for (W_String senten(MAXLEN+1); cin.getline((S_CHAR_P)senten, MAXLEN*2); ){
        if (senten.length() > MAXLEN) exit(-1);
#ifdef MAIN_DEBUG
        cerr << senten << endl;                   // 入力の表示
#endif // MAIN_DEBUG
        for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
            ukword.tran(senten[curpos]);
            indict.tran(senten[curpos]);
#ifdef MAIN_DEBUG
            fordebug(indict, intstr, curpos, senten);
#endif // MAIN_DEBUG
#ifdef EXDICT
            exdict.tran(senten[curpos]);
#ifdef MAIN_DEBUG
            fordebug(exdict, intstr, curpos, senten);
#endif // MAIN_DEBUG
            vtable.fill(indict, exdict, ukword);
#else
            vtable.fill(indict, ukword);
#endif // EXDICT
        }
        vtable.output(senten);

        ukword.init();
        indict.init();
#ifdef EXDICT
        exdict.init();
#endif // EXDICT
        vtable.init();
    }

    cerr << "Done" << endl;
}


//------------------------------------------------------------------------------------
//                       usage
//------------------------------------------------------------------------------------

void usage(const S_CHAR_P str)
{
    cerr << "Usage: " << str << "\n";
    exit(-1);
}

    
//------------------------------------------------------------------------------------
//                       fordebug
//------------------------------------------------------------------------------------

// 機  能 : 辞書検索の結果を表示する
//
// 注意点 : なし

void fordebug(const InDict& indict, const IntStr& intstr, const U_INT4 curpos,
              const W_CHAR_P senten)
{
    for (InMorp_P morp = indict.lenpos() ;morp->length > 0; morp++){
        for (U_INT2 pos = 0; pos+morp->length <= curpos; pos++) cerr << "  ";
        cerr << intstr[morp->part] << "/IN" << endl;
    }
}


//------------------------------------------------------------------------------------

void fordebug(const ExDict& exdict, const IntStr& intstr, const U_INT4 curpos,
              const W_CHAR_P senten)
{
    for (ExMorp_P morp = exdict.lenpos(); morp->length > 0; morp++){
        for (U_INT2 pos = 0; pos+morp->length <= curpos; pos++) cerr << "  ";
        cerr.write((S_CHAR_P)(senten+curpos+1-morp->length), morp->length*2);
        cerr << "/" << "EX" << endl;
    }
}


//====================================================================================
//                       END
//====================================================================================
