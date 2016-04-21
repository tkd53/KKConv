//====================================================================================
//                       VTable.h
//                            by Shinsuke MORI
//                            Last change : 24 April 1996
//====================================================================================

// ��  ǽ : Viterbi ���르�ꥺ���ɽ�Ȥ�������
//
// ����� : vtable[0][BT] �� vtable[curpos][BT] ��ξü�Ȥʤ롣


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

    U_INT4   statno;                              // �����ֹ�

    U_INT4   length;                              // Ĺ��

    enum ORIGIN { UD /*̤��*/, IN /*��������*/, EX /*��������*/, UM /*̤�θ�*/};

    ORIGIN   orig;                                // �н�

    DECIM8   logP;                                // ���ѳ�Ψ

    DPNode_P prev;                                // ľ���ΥΡ���

    DPNode_P foll;                                // ľ��ΥΡ���

    DPNode_P next;                                // ľ���ΥΡ���

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
        cerr << "���� orig �������Ǥ�\n";
        exit(-1);
    }

    return(s);
}


//------------------------------------------------------------------------------------
//                       class VTable
//------------------------------------------------------------------------------------

// ��  ǽ : Viterbi ���르�ꥺ���ɽ
//
// ����� : ���������� DPNode_P_P vtable ������

class VTable{

  public:

                  VTable(const IntStr&, const Markov&, U_INT4);

    void          init();                         // �����

//    void          fill(const InDict&, const UkWord&);
    void          fill(const InDict&, UkWord&);
                                                  // ưŪ�ײ�ˡ��ɽ�ι���

//    void          fill(const InDict&, const ExDict&, const UkWord&);
    void          fill(const InDict&, const ExDict&, UkWord&);
                                                  // ưŪ�ײ�ˡ��ɽ�ι���

    void          output(W_CHAR_P);               // ��̤ν���

    void          fprint(ostream&, U_INT4) const; // ���󥹥��󥹤�ɽ��

  private:

    const IntStr& intstr;                         // �����Ǥȿ������б�ɽ

    const Markov& markov;                         // �����ǥ�

    const U_INT4  maxlen;                         // Ĺ���κ�����

    DPNode_P_P    vtable;                         // ưŪ�ײ�ˡ��ɽ������

    DPNode_P_P    head;                           // �ư��֤Υꥹ�Ȥ���Ƭ

    U_INT4        curpos;                         // ���ߤΰ���(ʸƬ�����ʸ����)

    void          fill(const InDict&);            // ưŪ�ײ�ˡ��ɽ�ι���(��������)

    void          fill(const ExDict&);            // ưŪ�ײ�ˡ��ɽ�ι���(��������)

//    void          fill(const UkWord&);            // ưŪ�ײ�ˡ��ɽ�ι���(̤�η�����)
    void          fill(UkWord&);            // ưŪ�ײ�ˡ��ɽ�ι���(̤�η�����)

    void          fill(const U_INT4&, const U_INT4&, const DECIM8&,
                       const DPNode::ORIGIN&);    // ưŪ�ײ�ˡ��ɽ�ι���(������)

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ����������ˤ�������Ǥ�����
//
// ����� : �ʤ�

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ��������ˤ�������Ǥ�����
//
// ����� : �ʤ�

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ��̤�η����Ǥ�����
//
// ����� : �ʤ�

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ������� (statno, length) ������
//
// ����� : �ʤ�

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

// ��  ǽ : �����ѿ� head[curpos] �ȥ����ѿ� next ������
//
// ����� : �ʤ�

inline void VTable::postfill()
{
#ifdef VTable_DEBUG
    cerr << "VTable::postfill()" << endl;
#endif

    DPNode_P node = vtable[curpos];
    DPNode_P last = node+intstr.size;
    for (head[curpos] = NULL; node < last; node++){ // �����ѿ� head[curpos] ������
        if (node->length == 0) continue;
        head[curpos] = node;
        break;
    }
    if (head[curpos] == NULL) return;             // ���Ǥ��ʤ����
    for (DPNode_P next = node+1; next < last; next++){// �����ѿ� next ������
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
    fill(BT, 1, DECIM8(0), DPNode::IN);           // ʸ������ BT �ؤ�����
    assert(vtable[curpos][BT].length != 0);       // �򤬤�¸�ߤ���Ϥ�
    head[curpos] = &vtable[curpos][BT];           // for init()

// �����õ���ȥ��� foll ������
    for (DPNode_P node = head[curpos]; node->prev != NULL; node = node->prev){
        node->prev->foll = node;
    }

// ������õ���Ⱥ�����ɽ��
    for (DPNode_P node = head[0]->foll; node->foll != NULL; node = node->foll){
        if (node->statno == 0){                   // UT �ξ��
            cout.write((S_CHAR_P)sent, node->length*2);
            cout << "/" << node->orig << " ";
        }else{
            cout << intstr[node->statno] << "/" << node->orig << " ";
        }
//        cout << node->logP/log(2) << " ";         // �Ʒ����Ǥ�ľ��γ�Ψ�ͤ�ɽ��
        sent += node->length;
    }

    cout << head[curpos]->logP/log(2) << endl;    // ʸ���Τγ�Ψ�ͤ�ɽ��
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
