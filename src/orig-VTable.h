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
#include <minmax.h>

#include "constant.h"
#include "InMorp.h"
#include "ExMorp.h"
#include <IntStr.h>
#include <InDict.h>
#include <ExDict.h>
#include <Markov.h>
#include <UkYomi.h>


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

    enum ORIGIN { UD /*未定*/, IN /*内部辞書*/, EX /*外部辞書*/, UM /*未知語*/};

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

    DPNode_P_P    vtable;			  // 動的計画法の表

    DPNode_P_P    head;                           // 各位置のリストの先頭

    U_INT4        curpos;			  // 現在の位置(文頭からの文字数)

    void          fill(const InDict&);            // 動的計画法の表の更新(内部辞書)

    void          fill(const ExDict&);            // 動的計画法の表の更新(外部辞書)

    void          fill(const UkYomi&);            // 動的計画法の表の更新(未知単語)

    void          fill(const U_INT4&, const U_INT4&, const U_INT4&, const DECIM8&,
                       const DPNode::ORIGIN&);    // 動的計画法の表の更新(下請け)

    void          postfill();

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

    vtable = new DPNode_P[maxlen];
    for (U_INT4 i = 0; i < maxlen; i++) vtable[i] = new DPNode[intstr.size];
    vtable[0][BT].stat = BT;

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

    for (U_INT4 i = 1; i < curpos+1; i++){
        for (U_INT4 j = UT; j < intstr.size; j++){
            vtable[i][j].init();
        }
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
    postfill();
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
    postfill();
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
        fill(UT, length, 0, ukyomi.logP(length), DPNode::UM);
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

    for (DPNode_P node = head[curpos-length]; node; node = node->next){
        DECIM8 logP = node->logP+markov.logP(node->stat, stat)+LogP;
        if ((vtable[curpos][stat].length == 0) ||
            (vtable[curpos][stat].logP > logP)){
            vtable[curpos][stat] = DPNode(stat, length, text, orig, logP, node);
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
    for ( ; node < last; node++){                 // メンバ変数 head[curpos] の設定
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

void VTable::output(W_CHAR_P sent, IntStr& intext)
{
#ifdef VTable_DEBUG
    cerr << "VTable::output(W_CHAR_P, IntStr&)" << endl;
#endif

    curpos++;
    fill(BT, 1, 0, DECIM8(0), DPNode::IN);        // 文末記号 BT への遷移
    assert(vtable[curpos][BT].length != 0);       // 解がは存在するはず
    head[curpos] = &vtable[curpos][BT];           // for init()

//    cerr << "OK1\n";

// 後向き探索とメンバ foll の設定
    for (DPNode_P node = head[curpos]; node->prev != NULL; node = node->prev){
//        cerr << "Text = " << intext[node->text] << endl;
        node->prev->foll = node;
    }

//    cerr << "OK2\n";

// 前向き探索と最尤解の表示
    for (DPNode_P node = head[0]->foll; node->foll != NULL; node = node->foll){
        switch (node->orig){
        case 1:
            cout << intext[node->text];
            break;
        case 2:
            cerr << "メンバ変数 orig が不正です\n";
            exit(-1);
        case 3:
            cout.write((S_CHAR_P)sent, node->length*2);
            break;
        default:
            cerr << "メンバ変数 orig が不正です\n";
            exit(-1);
        }
        cout << "/" << node->orig << " ";
        sent += node->length;
    }

//    cerr << "OK3\n";
    cout.precision(5);
    cout << head[curpos]->logP/log(2);

    cout << endl;
}


//------------------------------------------------------------------------------------

void VTable::output(W_CHAR_P sent, IntStr& intext, IntStr& extext)
{
#ifdef VTable_DEBUG
    cerr << "VTable::output(W_CHAR_P, IntStr&, IntStr&)" << endl;
#endif

    curpos++;
    fill(BT, 1, 0, DECIM8(0), DPNode::IN);        // 文末記号 BT への遷移
    assert(vtable[curpos][BT].length != 0);       // 解がは存在するはず
    head[curpos] = &vtable[curpos][BT];           // for init()

// 後向き探索とメンバ foll の設定
    for (DPNode_P node = head[curpos]; node->prev != NULL; node = node->prev){
        node->prev->foll = node;
    }

// 前向き探索と最尤解の表示
    for (DPNode_P node = head[0]->foll; node->foll != NULL; node = node->foll){
        switch (node->orig){
        case 1:
            cout << intext[node->text];
            break;
        case 2:
            cout << extext[node->text];
            break;
        case 3:
            cout.write((S_CHAR_P)sent, node->length*2);
            break;
        default:
            cerr << "メンバ変数 orig が不正です\n";
            exit(-1);
        }
        cout << "/" << node->orig << " ";
        sent += node->length;
    }
//    cout.precision(20);
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
