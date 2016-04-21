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

    U_INT4   stat;                                // �����ֹ�

    U_INT4   length;                              // Ĺ��

    U_INT4   text;                                // �Ѵ����ɽ��

    enum ORIGIN { UD /*̤��*/, IN /*��������*/, EX /*��������*/, UW /*̤�θ�*/};

    ORIGIN   orig;                                // �н�

    DECIM8   logP;                                // ���ѳ�Ψ

    DPNode_P prev;                                // ľ���ΥΡ���

    DPNode_P foll;                                // ľ��ΥΡ���

    DPNode_P next;                                // ľ���ΥΡ���

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

    void          fill(const InDict&, const UkYomi&);
                                                  // ưŪ�ײ�ˡ��ɽ�ι���

    void          fill(const InDict&, const ExDict&, const UkYomi&);
                                                  // ưŪ�ײ�ˡ��ɽ�ι���

    void          output(W_CHAR_P, IntStr&);      // ��̤ν���

    void          output(W_CHAR_P, IntStr&, IntStr&);
                                                  // ��̤ν���

    void          fprint(ostream&, U_INT4) const; // ���󥹥��󥹤�ɽ��

  private:

    const IntStr& intstr;                         // ñ��ȿ������б�ɽ

    const Markov& markov;                         // �����ǥ�

    const U_INT4  maxlen;                         // Ĺ���κ�����

    typedef map<U_INT4, DPNode> DPColumn;
    typedef DPColumn* DPColumn_P;

    DPColumn_P    vtable;                         // ưŪ�ײ�ˡ��ɽ

    U_INT4        curpos;			  // ���ߤΰ���(ʸƬ�����ʸ����)

    void          fill(const InDict&);            // ưŪ�ײ�ˡ��ɽ�ι���(��������)

    void          fill(const ExDict&);            // ưŪ�ײ�ˡ��ɽ�ι���(��������)

    void          fill(const UkYomi&);            // ưŪ�ײ�ˡ��ɽ�ι���(̤�θ�)

    void          fill(const U_INT4&, const U_INT4&, const U_INT4&, const DECIM8&,
                       const DPNode::ORIGIN&);    // ưŪ�ײ�ˡ��ɽ�ι���(������)

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ����������ˤ���ñ�������
//
// ����� : �ʤ�

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ��������ˤ���ñ�������
//
// ����� : �ʤ�

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ��̤�θ������
//
// ����� : �ʤ�

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

// ��  ǽ : Viterbi ���르�ꥺ���ɽ vtable[curpos] ��ñ�� (stat, length) ������
//
// ����� : �ʤ�

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

    DPNode tail;                                  // ��ü�ΥΡ���
    for (DPColumn::iterator iter = vtable[curpos].begin();
         iter != vtable[curpos].end(); iter++){
        DECIM8 logP = (*iter).second.logP+markov.logP((*iter).first, BT);
        if ((tail.stat == UT) || (tail.logP > logP)){
            tail = DPNode(BT, 1, 0, DPNode::IN, logP, &(*iter).second);
        }
    }
    assert(tail.stat == BT);                      // �򤬤ʤ�
    curpos++;

// �����õ���ȥ��� foll ������
    DPNode_P node;
    for (node = &tail; node->prev != NULL; node = node->prev){
//        cerr << "Text = " << intext[node->text] << endl;
        node->prev->foll = node;
    }

// ������õ���Ⱥ�����ɽ��
    for (node = node->foll; node->foll != NULL; node = node->foll){
        switch (node->orig){
        case DPNode::IN:
            cout << intext[node->text];
            break;
        case DPNode::EX:
            cerr << "�����ѿ� orig = EX �������Ǥ� line: " << __LINE__ << endl;
            exit(-1);
        case DPNode::UW:
            cout.write((S_CHAR_P)sent, node->length*2);
            break;
        case DPNode::UD:
            cout << "�����ѿ� orig �� UD �Ǥ� line: " << __LINE__ << endl;
            exit(-1);
        default:
            cerr << "�����ѿ� orig �������Ǥ� line: " << __LINE__ << endl;
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

    DPNode tail;                                  // ��ü�ΥΡ���
    for (DPColumn::iterator iter = vtable[curpos].begin();
         iter != vtable[curpos].end(); iter++){
        DECIM8 logP = (*iter).second.logP+markov.logP((*iter).first, BT);
        if ((tail.stat == UT) || (tail.logP > logP)){
            tail = DPNode(BT, 1, 0, DPNode::IN, logP, &(*iter).second);
        }
    }
    assert(tail.stat == BT);                      // �򤬤ʤ�
    curpos++;

// �����õ���ȥ��� foll ������
    DPNode_P node;
    for (node = &tail; node->prev != NULL; node = node->prev){
//        cerr << "Text = " << intext[node->text] << endl;
        node->prev->foll = node;
    }

// ������õ���Ⱥ�����ɽ��
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
            cerr << "�����ѿ� orig �� UD �Ǥ� line: " << __LINE__ << endl;
            exit(-1);
        default:
            cerr << "�����ѿ� orig �������Ǥ� line: " << __LINE__ << endl;
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
