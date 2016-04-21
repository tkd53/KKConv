//====================================================================================
//                       main.cc
//                            by Shinsuke MORI
//                            Last change : 4 March 1995
//====================================================================================

// ��  ǽ : ������ 2-gram ��ǥ�ˤ������ǲ��ϴ�
//
// ����ˡ : main < (filename)
//
// ��  �� : main < ../../corpus/NKN10.senten
//
// ����� : �ʻ����̤�������ü췿(���ʻ�)


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#define EXDICT                                    // ������������Ѥ���

//#define AC                                        // ����� AC ˡ
#define DA                                        // ����� DA ˡ
#define MEMORY                                    // �絭���˺ܤ���

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
    if (argc != 1) usage(argv[0]);                // �����Υ����å�

    IntStr intstr("WordIntStr");                  // �ʻ��ֹ椫���ʻ�ɽ���ؤα���
    Markov markov("WordMarkov", "WordLambda");    // �ޥ륳�ե�ǥ�
    UkWord ukword(MAXLEN);                        // ̤�θ��ǥ�
    InDict indict("InDict");                      // ��������Υ����ȥޥȥ�
#ifdef EXDICT
    ExDict exdict("ExDict");                      // ��������Υ����ȥޥȥ�
#endif // EXDICT
    VTable vtable(intstr, markov, MAXLEN);        // Viterbi Table
    cerr << "Initialize Done" << endl;

    for (W_String senten(MAXLEN+1); cin.getline((S_CHAR_P)senten, MAXLEN*2); ){
        if (senten.length() > MAXLEN) exit(-1);
#ifdef MAIN_DEBUG
        cerr << senten << endl;                   // ���Ϥ�ɽ��
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

// ��  ǽ : ���񸡺��η�̤�ɽ������
//
// ����� : �ʤ�

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
