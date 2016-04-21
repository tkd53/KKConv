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

#include <math.h>
#include <mystd.h>
#include <minmax.h>

#include "UkWord.h"
//#include "UkWordWithSArray.h"
#include "Markov.h"
#include "IntStr.h"
#include "InMorp.h"
#include "ExMorp.h"


//------------------------------------------------------------------------------------
//                       class DPNode
//------------------------------------------------------------------------------------

class DPNode;
typedef DPNode* DPNode_P;
typedef DPNode** DPNode_P_P;

class DPNode{

  public:

    U_INT4   statno;                              // 状態番号

    U_INT4   length;                              // 長さ

    enum ORIGIN { UD /*未定*/, IN /*内部辞書*/, EX /*外部辞書*/, UM /*未知語*/};

    ORIGIN   orig;                                // 出処

    DECIM8   logP;                                // 累積確率

    DPNode_P prev;                                // 直前のノード

    DPNode_P foll;                                // 直後のノード

    DPNode_P next;                                // 直下のノード

             DPNode();

             DPNode(U_INT4, U_INT4, ORIGIN, DECIM8, DPNode_P);

    void     init();

friend ostream& operator<<(ostream&, const IntStr&);

  private:

};


//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

inline DPNode::DPNode()
: statno(0), length(0), orig(UD), logP(0.0), prev(NULL), foll(NULL), next(NULL)
{
    ;                                             // No Operation
}


//------------------------------------------------------------------------------------

inline DPNode::DPNode(U_INT4 statno, U_INT4 length, ORIGIN orig, DECIM8 logP,
                      DPNode_P prev)
: statno(statno), length(length), orig(orig), logP(logP), prev(prev), foll(NULL),
  next(NULL)
{
    ;                                             // No Operation
}


//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

inline void DPNode::init()
{
    statno = 0;
    length = 0;
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
    s << "(" << setw(2) << node.length << "," << setw(2) << node.statno << ")";
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
    case DPNode::UM:
        cout << "UM";
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

//    void          fill(const InDict&, const UkWord&);
    void          fill(const InDict&, UkWord&);
                                                  // 動的計画法の表の更新

//    void          fill(const InDict&, const ExDict&, const UkWord&);
    void          fill(const InDict&, const ExDict&, UkWord&);
                                                  // 動的計画法の表の更新

    void          output(W_CHAR_P);               // 結果の出力

    void          fprint(ostream&, U_INT4) const; // インスタンスの表示

  private:

    const IntStr& intstr;                         // 形態素と数字の対応表

    const Markov& markov;                         // 言語モデル

    const U_INT4  maxlen;                         // 長さの最大値

    DPNode_P_P    vtable;                         // 動的計画法の表の本体

    DPNode_P_P    head;                           // 各位置のリストの先頭

    U_INT4        curpos;                         // 現在の位置(文頭からの文字数)

    void          fill(const InDict&);            // 動的計画法の表の更新(内部辞書)

    void          fill(const ExDict&);            // 動的計画法の表の更新(外部辞書)

//    void          fill(const UkWord&);            // 動的計画法の表の更新(未知形態素)
    void          fill(UkWord&);            // 動的計画法の表の更新(未知形態素)

    void          fill(const U_INT4&, const U_INT4&, const DECIM8&,
                       const DPNode::ORIGIN&);    // 動的計画法の表の更新(下請け)

    void          postfill();

};


//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

VTable::VTable(const IntStr& intstr, const Markov& markov, U_INT4 maxlen)
: intstr(intstr), markov(markov), maxlen(maxlen), curpos(0)
{
#ifdef VTable_DEBUG
    cerr << "VTable::VTable(const IntStr&, const Markov&, U_INT4)" << endl;
#endif

    vtable = new DPNode_P[maxlen];
    for (U_INT4 i = 0; i < maxlen; i++) vtable[i] = new DPNode[intstr.size];
    vtable[0][BT].statno = BT;

    head = new DPNode_P[maxlen];
    head[0] = &vtable[0][BT];
}


//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

void VTable::init()
{
#ifdef VTable_DEBUG
    cerr << "VTable::init()" << endl;
#endif

    for (U_INT4 i = 1; i <= curpos; i++){
        for (U_INT4 j = UT; j < intstr.size; j++){
            vtable[i][j].init();
        }
    }

    curpos = 0;
}


//------------------------------------------------------------------------------------
//                       fill
//------------------------------------------------------------------------------------

//void VTable::fill(const InDict& indict, const UkWord& ukword)
void VTable::fill(const InDict& indict, UkWord& ukword)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const InDict&, const UkWord&)" << endl;
#endif

    curpos++;
    fill(indict);
    fill(ukword);
    postfill();
}


//------------------------------------------------------------------------------------

//void VTable::fill(const InDict& indict, const ExDict& exdict, const UkWord& ukword)
void VTable::fill(const InDict& indict, const ExDict& exdict, UkWord& ukword)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const InDict&, const ExDict&, const UkWord&)" << endl;
#endif

    curpos++;
    fill(indict);
    fill(exdict);
    fill(ukword);
    postfill();
}


//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を内部辞書にある形態素で埋める
//
// 注意点 : なし

inline void VTable::fill(const InDict& indict)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const InDict&)" << endl;
#endif

    for (InMorp_P morp = indict.lenpos(); morp->length > 0; morp++){
        fill(morp->part, morp->length, DECIM8(0), DPNode::IN);
    }
}


//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を外部辞書にある形態素で埋める
//
// 注意点 : なし

inline void VTable::fill(const ExDict& exdict)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(const ExDict&)" << endl;
#endif

    for (ExMorp_P morp = exdict.lenpos(); morp->length > 0; morp++){
        fill(UT, morp->length, morp->logP, DPNode::EX);
    }
}


//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を未知形態素で埋める
//
// 注意点 : なし

inline void VTable::fill(UkWord& ukword)
//inline void VTable::fill(const UkWord& ukword)
{
#ifdef VTable_DEBUG
    cerr << "VTable::fill(UkWord&)" << endl;
#endif

    const U_INT4 part = 0;
    for (U_INT4 length = min(curpos, UkWordMaxLen); length > 0; length--){
        fill(part, length, ukword.logP(length), DPNode::UM);
    }
}


//------------------------------------------------------------------------------------

// 機  能 : Viterbi アルゴリズムの表 vtable[curpos] を形態素 (statno, length) で埋める
//
// 注意点 : なし

inline void VTable::fill(const U_INT4& statno, const U_INT4& length,
                         const DECIM8& LogP, const DPNode::ORIGIN& orig){
#ifdef VTABLE_DEBUG
    cerr << "VTable::fill(const U_INT4&, const U_INT4&, const DECIM8&, "
         << "const DPNode::ORIGIN&)" << endl;
#endif

    for (DPNode_P node = head[curpos-length]; node; node = node->next){
        DECIM8 logP = node->logP+markov.logP(node->statno, statno)+LogP;
        if ((vtable[curpos][statno].length == 0) ||
            (vtable[curpos][statno].logP > logP)){
            vtable[curpos][statno] = DPNode(statno, length, orig, logP, node);
        }
    }
}


//------------------------------------------------------------------------------------
//                       postfill
//------------------------------------------------------------------------------------

// 機  能 : メンバ変数 head[curpos] とメンバ変数 next の設定
//
// 注意点 : なし

inline void VTable::postfill()
{
#ifdef VTable_DEBUG
    cerr << "VTable::postfill()" << endl;
#endif

    DPNode_P node = vtable[curpos];
    DPNode_P last = node+intstr.size;
    for (head[curpos] = NULL; node < last; node++){ // メンバ変数 head[curpos] の設定
        if (node->length == 0) continue;
        head[curpos] = node;
        break;
    }
    if (head[curpos] == NULL) return;             // 要素がない場合
    for (DPNode_P next = node+1; next < last; next++){// メンバ変数 next の設定
        if (next->length == 0) continue;
        node->next = next;
        node = next;
    }
}


//------------------------------------------------------------------------------------
//                       output
//------------------------------------------------------------------------------------

void VTable::output(W_CHAR_P sent)
{
#ifdef VTable_DEBUG
    cerr << "VTable::output(W_CHAR_P)" << endl;
#endif

    curpos++;
    fill(BT, 1, DECIM8(0), DPNode::IN);           // 文末記号 BT への遷移
    assert(vtable[curpos][BT].length != 0);       // 解がは存在するはず
    head[curpos] = &vtable[curpos][BT];           // for init()

// 後向き探索とメンバ foll の設定
    for (DPNode_P node = head[curpos]; node->prev != NULL; node = node->prev){
        node->prev->foll = node;
    }

// 前向き探索と最尤解の表示
    for (DPNode_P node = head[0]->foll; node->foll != NULL; node = node->foll){
        if (node->statno == 0){                   // UT の場合
            cout.write((S_CHAR_P)sent, node->length*2);
            cout << "/" << node->orig << " ";
        }else{
            cout << intstr[node->statno] << "/" << node->orig << " ";
        }
//        cout << node->logP/log(2) << " ";         // 各形態素の直後の確率値を表示
        sent += node->length;
    }

    cout << head[curpos]->logP/log(2) << endl;    // 文全体の確率値を表示
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
