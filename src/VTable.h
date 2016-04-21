//====================================================================================
//                       VTable.h
//                            by Shinsuke MORI
//                            Last change : 24 April 1996
//====================================================================================

// 機  能 : Viterbi アルゴリズムの表とその要素
//
// 注意点 : vtable[0][BT] と vtable[curpos][BT] が両端となる。


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _VTable_h
#define _VTable_h

#ifdef DEBUG
#define VTable_DEBUG
#endif
//#define VTable_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <mystd.h>
//#include <minmax.h>

#include "constant.h"
#include "InMorp.h"
#include "ExMorp.h"
#include <IntStr.h>
#include <InDict.h>
#include <ExDict.h>
#include <Markov.h>
#include <UkYomi.h>

#include <map>


//------------------------------------------------------------------------------------
//                       class DPNode
//------------------------------------------------------------------------------------

class DPNode;
typedef DPNode* DPNode_P;
typedef DPNode** DPNode_P_P;

class DPNode{

  public:

    U_INT4   stat;                                // 状態番号

    U_INT4   length;                              // 長さ

    U_INT4   text;                                // 変換後の表記

    enum ORIGIN { UD /*未定*/, IN /*内部辞書*/, EX /*外部辞書*/, UW /*未知語*/};

    ORIGIN   orig;                                // 出処

    DECIM8   logP;                                // 累積確率

    DPNode_P prev;                                // 直前のノード

    DPNode_P foll;                                // 直後のノード

    DPNode_P next;                                // 直下のノード

             DPNode();

             DPNode(U_INT4, U_INT4, U_INT4, ORIGIN, DECIM8, DPNode_P);

    void     init();

friend ostream& operator<<(ostream&, const IntStr&);

  private:

};


//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

inline DPNode::DPNode()
: stat(0), length(0), text(0), orig(UD), logP(0.0), prev(NULL), foll(NULL), next(NULL)
{
    ;                                             // No Operation;
}

inline DPNode::DPNode(U_INT4 stat, U_INT4 length, U_INT4 text, ORIGIN orig,
                      DECIM8 logP, DPNode_P prev)
: stat(stat), length(length), text(text), orig(orig), logP(logP), prev(prev),
  foll(NULL), next(NULL)
{
    ;                                             // No Operation;
}


//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

inline void DPNode::init()
{
    stat = 0;
    length = 0;
    text = 0;
    orig = UD;
    logP = 0.0;
    prev = NULL;
    foll = NULL;
    next = NULL;
}


//------------------------------------------------------------------------------------
//                       operator<<
//------------------------------------------------------------------------------------

inline ostream& operator<<(ostream& s, const DPNode& node)
{
    s << "(" << setw(2) << node.length << "," << setw(2) << node.stat << ")";
    return(s);
}


//------------------------------------------------------------------------------------

inline ostream& operator<<(ostream& s, const DPNode::ORIGIN& orig)
{
#ifdef VTable_DEBUG
    cerr << "operator<<(ostream&, const DPNode::ORIGIN&)" << endl;
#endif

    switch (orig){
    case DPNode::IN:
        cout << "IN";
        break;
    case DPNode::EX:
        cout << "EX";
        break;
    case DPNode::UW:
        cout << "UW";
        break;
    case DPNode::UD:
        cout << "UD";
        break;
    default:
        cerr << "引数 orig が不正です\n";
        exit(-1);
    }

    return(s);
}


//------------------------------------------------------------------------------------
//                       class VTable
//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表
//
// 注意点 : ２次元配列 DPNode_P_P vtable が本体

class VTable{

  public:

                  VTable(const IntStr&, const Markov&, U_INT4);

    void          init();                         // 初期化

    void          fill(const InDict&, const UkYomi&);
                                                  // 動的計画法の表の更新

    void          fill(const InDict&, const ExDict&, const UkYomi&);
                                                  // 動的計画法の表の更新

    void          output(W_CHAR_P, IntStr&);      // 結果の出力

    void          output(W_CHAR_P, IntStr&, IntStr&);
                                                  // 結果の出力

    void          fprint(ostream&, U_INT4) const; // インスタンスの表示

  private:

    const IntStr& intstr;                         // 単語と数字の対応表

    const Markov& markov;                         // 言語モデル

    const U_INT4  maxlen;                         // 長さの最大値

    typedef map<U_INT4, DPNode> DPColumn;
    typedef DPColumn* DPColumn_P;

    DPColumn_P    vtable;                         // 動的計画法の表

    U_INT4        curpos;			  // 現在の位置(文頭からの文字数)

    void          fill(const InDict&);            // 動的計画法の表の更新(内部辞書)

    void          fill(const ExDict&);            // 動的計画法の表の更新(外部辞書)

    void          fill(const UkYomi&);            // 動的計画法の表の更新(未知語)

    void          fill(const U_INT4&, const U_INT4&, const U_INT4&, const DECIM8&,
                       const DPNode::ORIGIN&);    // 動的計画法の表の更新(下請け)

};


//------------------------------------------------------------------------------------
//                       constractor
//------------------------------------------------------------------------------------

VTable::VTable(const IntStr& intstr, const Markov& markov, U_INT4 maxlen)
: intstr(intstr), markov(markov), maxlen(maxlen), curpos(0)
{
#ifdef VTable_DEBUG
    cerr << "VTable::VTable(const IntStr&, const Markov&, U_INT4)" << endl;
#endif

    vtable = new DPColumn[maxlen];
    vtable[0][BT] = DPNode(BT, 1, 1, DPNode::IN, 0, NULL);
}


//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

void VTable::init()
{
#ifdef VTable_DEBUG
    cerr << "VTable::init()" << endl;
#endif

    for (U_INT4 i = 1; i < curpos+1; i++){
        vtable[i].erase(vtable[i].begin(), vtable[i].end());
    }

    curpos = 0;
}


//------------------------------------------------------------------------------------
//                       fill
//------------------------------------------------------------------------------------

void VTable::fill(const InDict& indict, const UkYomi& ukyomi)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const InDict&, const UkYomi&)" << endl;
#endif

    curpos++;
    fill(indict);
    fill(ukyomi);
}


//------------------------------------------------------------------------------------

void VTable::fill(const InDict& indict, const ExDict& exdict, const UkYomi& ukyomi)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const InDict&, const ExDict&, const UkYomi&)" << endl;
#endif

    curpos++;
    fill(indict);
    fill(exdict);
    fill(ukyomi);
}

//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を内部辞書にある単語で埋める
//
// 注意点 : なし

inline void VTable::fill(const InDict& indict)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const InDict&)" << endl;
#endif

    for (InMorp_P morp = indict.lenpos(); morp->length > 0; morp++){
        fill(morp->stat, morp->length, morp->stat, morp->logP, DPNode::IN);
    }
}


//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を外部辞書にある単語で埋める
//
// 注意点 : なし

inline void VTable::fill(const ExDict& exdict)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const ExDict&)" << endl;
#endif

    for (ExMorp_P morp = exdict.lenpos(); morp->length > 0; morp++){
        fill(UT, morp->length, morp->text, morp->logP, DPNode::EX);
    }
}


//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を未知語で埋める
//
// 注意点 : なし

inline void VTable::fill(const UkYomi& ukyomi)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(UkYomi&)" << endl;
#endif

    for (U_INT4 length = min(curpos, UkYomiMaxLen); length > 0; length--){
        fill(UT, length, 0, ukyomi.logP(length), DPNode::UW);
    }
}


//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を単語 (stat, length) で埋める
//
// 注意点 : なし

inline void VTable::fill(const U_INT4& stat, const U_INT4& length,
                         const U_INT4& text, const DECIM8& LogP,
                         const DPNode::ORIGIN& orig)
{
#ifdef VTABLE_DEBUG
    cerr << "VTable::fill(const U_INT4&, const U_INT4&, const DECIM8&, "
         << "const DPNode::ORIGIN&)" << endl;
#endif

    for (DPColumn::iterator iter = vtable[curpos-length].begin();
         iter != vtable[curpos-length].end(); iter++){
        DECIM8 logP = (*iter).second.logP+markov.logP((*iter).first, stat)+LogP;
        if ((vtable[curpos].find(stat) == vtable[curpos].end()) ||
            (vtable[curpos][stat].logP > logP)){
            vtable[curpos][stat]
                = DPNode(stat, length, text, orig, logP, &(*iter).second);
        }
    }
}


//------------------------------------------------------------------------------------
//                       output
//------------------------------------------------------------------------------------

void VTable::output(W_CHAR_P sent, IntStr& intext)
{
#ifdef VTable_DEBUG
    cerr << "VTable::output(W_CHAR_P, IntStr&)" << endl;
#endif

    DPNode tail;                                  // 終端のノード
    for (DPColumn::iterator iter = vtable[curpos].begin();
         iter != vtable[curpos].end(); iter++){
        DECIM8 logP = (*iter).second.logP+markov.logP((*iter).first, BT);
        if ((tail.stat == UT) || (tail.logP > logP)){
            tail = DPNode(BT, 1, 0, DPNode::IN, logP, &(*iter).second);
        }
    }
    assert(tail.stat == BT);                      // 解がない
    curpos++;

// 後向き探索とメンバ foll の設定
    DPNode_P node;
    for (node = &tail; node->prev != NULL; node = node->prev){
//        cerr << "Text = " << intext[node->text] << endl;
        node->prev->foll = node;
    }

// 前向き探索と最尤解の表示
    for (node = node->foll; node->foll != NULL; node = node->foll){
        switch (node->orig){
        case DPNode::IN:
            cout << intext[node->text];
            break;
        case DPNode::EX:
            cerr << "メンバ変数 orig = EX が不正です line: " << __LINE__ << endl;
            exit(-1);
        case DPNode::UW:
            cout.write((S_CHAR_P)sent, node->length*2);
            break;
        case DPNode::UD:
            cout << "メンバ変数 orig が UD です line: " << __LINE__ << endl;
            exit(-1);
        default:
            cerr << "メンバ変数 orig が不正です line: " << __LINE__ << endl;
            exit(-1);
        }
        cout << "/" << node->orig << " ";
        sent += node->length;
    }

//    cout.precision(5);
//    cout << head[curpos]->logP/log(2);

    cout << endl;
}


//------------------------------------------------------------------------------------

void VTable::output(W_CHAR_P sent, IntStr& intext, IntStr& extext)
{
#ifdef VTable_DEBUG
    cerr << "VTable::output(W_CHAR_P, IntStr&, IntStr&)" << endl;
#endif

    DPNode tail;                                  // 終端のノード
    for (DPColumn::iterator iter = vtable[curpos].begin();
         iter != vtable[curpos].end(); iter++){
        DECIM8 logP = (*iter).second.logP+markov.logP((*iter).first, BT);
        if ((tail.stat == UT) || (tail.logP > logP)){
            tail = DPNode(BT, 1, 0, DPNode::IN, logP, &(*iter).second);
        }
    }
    assert(tail.stat == BT);                      // 解がない
    curpos++;

// 後向き探索とメンバ foll の設定
    DPNode_P node;
    for (node = &tail; node->prev != NULL; node = node->prev){
//        cerr << "Text = " << intext[node->text] << endl;
        node->prev->foll = node;
    }

// 前向き探索と最尤解の表示
    for (node = node->foll; node->foll != NULL; node = node->foll){
        switch (node->orig){
        case DPNode::IN:
            cout << intext[node->text];
            break;
        case DPNode::EX:
            cout << extext[node->text];
            break;
        case DPNode::UW:
            cout.write((S_CHAR_P)sent, node->length*2);
            break;
        case DPNode::UD:
            cerr << "メンバ変数 orig が UD です line: " << __LINE__ << endl;
            exit(-1);
        default:
            cerr << "メンバ変数 orig が不正です line: " << __LINE__ << endl;
            exit(-1);
        }
        cout << "/" << node->orig << " ";
        sent += node->length;
    }

//    cout.precision(5);
//    cout << head[curpos]->logP/log(2);

    cout << endl;
}


//------------------------------------------------------------------------------------
//                       fprint
//------------------------------------------------------------------------------------

void VTable::fprint(ostream& fout = cout, U_INT4 maxpos = 100) const
{
    fout << "   ";
    for (U_INT4 suf2 = 0; suf2 < maxpos; suf2 += 2) fout << suf2/10 << " ";
    fout << endl;

    fout << "   ";
    for (U_INT4 suf2 = 0; suf2 < maxpos; suf2 += 2) fout << suf2%10 << " ";
    fout << endl;

    fout << "---";
    for (U_INT4 suf2 = 0; suf2 < maxpos; suf2 += 2) fout << "--";
    fout << endl;

    for (U_INT4 suf1 = 0; suf1 < intstr.size; suf1++){
        fout << setw(2) << suf1 << " ";
        for (U_INT4 suf2 = 0; suf2 < maxpos; suf2 += 2){
            fout << vtable[suf2][suf1];
        }
        fout << endl;
    }
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
