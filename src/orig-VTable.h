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

    U_INT4   stat;                                // �����ֹ�

    U_INT4   length;                              // Ĺ��

    U_INT4   text;                                // �Ѵ����ɽ��

    enum ORIGIN { UD /*̤��*/, IN /*��������*/, EX /*��������*/, UM /*̤�θ�*/};

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

    DPNode_P_P    vtable;			  // ưŪ�ײ�ˡ��ɽ

    DPNode_P_P    head;                           // �ư��֤Υꥹ�Ȥ���Ƭ

    U_INT4        curpos;			  // ���ߤΰ���(ʸƬ�����ʸ����)

    void          fill(const InDict&);            // ưŪ�ײ�ˡ��ɽ�ι���(��������)

    void          fill(const ExDict&);            // ưŪ�ײ�ˡ��ɽ�ι���(��������)

    void          fill(const UkYomi&);            // ưŪ�ײ�ˡ��ɽ�ι���(̤��ñ��)

    void          fill(const U_INT4&, const U_INT4&, const U_INT4&, const DECIM8&,
                       const DPNode::ORIGIN&);    // ưŪ�ײ�ˡ��ɽ�ι���(������)

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
        fill(UT, length, 0, ukyomi.logP(length), DPNode::UM);
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
    for ( ; node < last; node++){                 // �����ѿ� head[curpos] ������
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

void VTable::output(W_CHAR_P sent, IntStr& intext)
{
#ifdef VTable_DEBUG
    cerr << "VTable::output(W_CHAR_P, IntStr&)" << endl;
#endif

    curpos++;
    fill(BT, 1, 0, DECIM8(0), DPNode::IN);        // ʸ������ BT �ؤ�����
    assert(vtable[curpos][BT].length != 0);       // �򤬤�¸�ߤ���Ϥ�
    head[curpos] = &vtable[curpos][BT];           // for init()

//    cerr << "OK1\n";

// �����õ���ȥ��� foll ������
    for (DPNode_P node = head[curpos]; node->prev != NULL; node = node->prev){
//        cerr << "Text = " << intext[node->text] << endl;
        node->prev->foll = node;
    }

//    cerr << "OK2\n";

// ������õ���Ⱥ�����ɽ��
    for (DPNode_P node = head[0]->foll; node->foll != NULL; node = node->foll){
        switch (node->orig){
        case 1:
            cout << intext[node->text];
            break;
        case 2:
            cerr << "�����ѿ� orig �������Ǥ�\n";
            exit(-1);
        case 3:
            cout.write((S_CHAR_P)sent, node->length*2);
            break;
        default:
            cerr << "�����ѿ� orig �������Ǥ�\n";
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
    fill(BT, 1, 0, DECIM8(0), DPNode::IN);        // ʸ������ BT �ؤ�����
    assert(vtable[curpos][BT].length != 0);       // �򤬤�¸�ߤ���Ϥ�
    head[curpos] = &vtable[curpos][BT];           // for init()

// �����õ���ȥ��� foll ������
    for (DPNode_P node = head[curpos]; node->prev != NULL; node = node->prev){
        node->prev->foll = node;
    }

// ������õ���Ⱥ�����ɽ��
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
            cerr << "�����ѿ� orig �������Ǥ�\n";
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
