//====================================================================================
//                       DPNode.h
//                            by Shinsuke MORI
//                            Last change : 24 April 1996
//====================================================================================

// ��  ǽ : Viterbi ���르�ꥺ��ΥΡ���
//
// ����� : VTableWithIV.h �ǤΤ߻���


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

    U_INT4   stat;                                // �����ֹ� for IntStr or ɽ���ֹ�

    U_INT4   length;                              // �б��������ϵ������Ĺ��

    WORD     word;                                // �Ѵ����ɽ��

    enum ORIGIN { UD /*̤��*/, IN /*��������*/, IV /*����ñ��*/, UM /*̤�θ�*/};

    ORIGIN   orig;                                // �н�

    DECIM8   logP;                                // ���ѳ�Ψ

    DPNode_P prev;                                // ľ���ΥΡ���

    DPNode_P foll;                                // ľ��ΥΡ���

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
        cerr << "���� orig �������Ǥ�: " << endl;
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
