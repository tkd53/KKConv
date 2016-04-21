//====================================================================================
//                       DPNode.h
//                            by Shinsuke MORI
//                            Last change : 24 April 1996
//====================================================================================

// 機  能 : Viterbi アルゴリズムのノード
//
// 注意点 : VTableWithIV.h でのみ使用


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _DPNode_h
#define _DPNode_h 1

#ifdef DEBUG
#define DPNode_DEBUG
#endif
//#define DPNode_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <mystd.h>
#include <Word.h>


//------------------------------------------------------------------------------------
//                       class DPNode
//------------------------------------------------------------------------------------

class DPNode;
typedef DPNode* DPNode_P;
typedef DPNode** DPNode_P_P;

class DPNode{

  public:

    U_INT4   stat;                                // 状態番号 for IntStr or 表記番号

    U_INT4   length;                              // 対応する入力記号列の長さ

    WORD     word;                                // 変換後の表記

    enum ORIGIN { UD /*未定*/, IN /*内部辞書*/, IV /*生コ単語*/, UM /*未知語*/};

    ORIGIN   orig;                                // 出処

    DECIM8   logP;                                // 累積確率

    DPNode_P prev;                                // 直前のノード

    DPNode_P foll;                                // 直後のノード

             DPNode();

             DPNode(const W_CHAR&);

             DPNode(U_INT4, U_INT4, WORD, ORIGIN, DECIM8, const DPNode_P);

    void     init();

    friend ostream& operator<<(ostream&, const IntStr&);

  private:

};


//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

inline DPNode::DPNode()
: stat(0), length(0), word(0), orig(UD), logP(0.0), prev(NULL), foll(NULL)
{
    ;                                             // No Operation;
}

inline DPNode::DPNode(const W_CHAR& wc)
: stat(0), length(0), word(1, wc), orig(UD), logP(0.0), prev(NULL), foll(NULL)
{
    ;                                             // No Operation;
}

inline DPNode::DPNode(U_INT4 stat, U_INT4 length, WORD word, ORIGIN orig, DECIM8 logP,
                      const DPNode_P prev)
: stat(stat), length(length), word(word), orig(orig), logP(logP), prev(prev),
  foll(NULL)
{
    ;                                             // No Operation;
}


//------------------------------------------------------------------------------------
//                       init
//------------------------------------------------------------------------------------

inline void DPNode::init()
{
#ifdef VTable_DEBUG
    cerr << "DPNode::init()" << endl;
#endif

    stat = 0;
    length = 0;
    word = WORD(0);
    orig = UD;
    logP = 0.0;
    prev = NULL;
    foll = NULL;
}


//------------------------------------------------------------------------------------
//                       operator<<
//------------------------------------------------------------------------------------

inline ostream& operator<<(ostream& s, const DPNode& node)
{
#ifdef VTable_DEBUG
    cerr << "operator<<(ostream&, const DPNode&)" << endl;
#endif

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
        s << "IN";
        break;
    case DPNode::IV:
        s << "IV";
        break;
    case DPNode::UM:
        s << "UM";
        break;
    case DPNode::UD:
        s << "UD";
        break;
    default:
        cerr << "引数 orig が不正です: " << endl;
        exit(-1);
    }

    return(s);
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
