  //====================================================================================
//                       main.cc
//                            by Shinsuke MORI
//                            Last change : 4 March 1995
//====================================================================================

// ��  ǽ : ñ����ɤߤ��Ȥ� 2-gram ��ǥ�ˤ�벾̾�����Ѵ���
//
// ����ˡ : main < (filename)
//
// ��  �� : main < ../../corpus/10.kkci
//
// ����� : �ʤ�


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------
#define DEBUG
#define EXDICT                                    // ������������

#ifdef DEBUG
#define MAIN_DEBUG
#endif

//#define MAIN_DEBUG                                // ��������η�̤�ɽ��

//#define AC
#define DA
#define MEMORY

//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <mystd.h>

#include <W_CHAR.h>

#include "constant.h"
#include "InMorp.h"
#include "ExMorp.h"
#include "VTable.h"
#include <IntStr.h>
#include <InDict.h>
#include <ExDict.h>
#include <Markov.h>
#include <UkYomi.h>


//------------------------------------------------------------------------------------
//                       prototypes
//------------------------------------------------------------------------------------

void usage(S_CHAR_P);
void dict(/*const*/ InDict&, const IntStr&, const U_INT4, const W_CHAR_P);
void dict(/*const*/ ExDict&, const IntStr&, const U_INT4, const W_CHAR_P);


//------------------------------------------------------------------------------------
//                       main
//------------------------------------------------------------------------------------

int main(int argc, S_CHAR_P argv[])
{
    std::string tkd53home = TKD53HOME;

    if (argc != 1) usage(argv[0]);                // �����Υ����å�

    IntStr intstr(tkd53home + "/dictionary/KKConv/WordKKCI-2/Step" + STEP + "/WordIntStr");                  // �ʻ��ֹ椫���ʻ�ɽ���ؤ��б�
    Markov markov(tkd53home + "/dictionary/KKConv/WordKKCI-2/Step" + STEP + "/WordMarkov",
    tkd53home + "/dictionary/KKConv/WordKKCI-2/Step" + STEP + "/WordLambda");    // �ޥ륳�ե�ǥ�
    UkYomi ukyomi(MAXLEN);                        // ̤���ɤߥ�ǥ� P(y)

    InDict indict(tkd53home + "/dictionary/KKConv/WordKKCI-2/Step" + STEP + "/InDict");                      // ��������Υ����ȥޥȥ�
#ifdef EXDICT
    ExDict exdict(tkd53home + "/dictionary/KKConv/WordKKCI-2/Step"+ STEP + "/ExDict");                      // ��������Υ����ȥޥȥ�
    IntStr extext(tkd53home + "/dictionary/KKConv/WordKKCI-2/Step"+ STEP + "/ExDict");                      // ɽ���ֹ椫��ɽ���ؤ��б�
#endif // EXDICT

    VTable vtable(intstr, markov, MAXLEN);        // Viterbi Table
    cerr << "Initialize Done" << endl;

    for (W_String senten(MAXLEN+1); cin.getline((S_CHAR_P)senten, MAXLEN*2); ){
        if (senten.length() > MAXLEN) exit(-1);
#ifdef MAIN_DEBUG
        cerr << senten << endl;                   // ���Ϥ�ɽ��
#endif // MAIN_DEBUG
        for (U_INT4 curpos = 0; senten[curpos].half.hi; curpos++){
            ukyomi.tran(senten[curpos]);
            indict.tran(senten[curpos]);
#ifdef MAIN_DEBUG
            dict(indict, intstr, curpos, senten);
#endif // MAIN_DEBUG
#ifdef EXDICT
            exdict.tran(senten[curpos]);
#ifdef MAIN_DEBUG
            dict(exdict, extext, curpos, senten);
#endif // MAIN_DEBUG
            vtable.fill(indict, exdict, ukyomi);
#else
            vtable.fill(indict, ukyomi);
#endif // EXDICT
        }
#ifdef EXDICT
        vtable.output(senten, intstr, extext);
#else
        vtable.output(senten, intstr);
#endif // EXDICT
        ukyomi.init();
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

void usage(S_CHAR string[])
{
    cerr << "Usage: " << string << "\n";
    exit(-1);
}


//------------------------------------------------------------------------------------
//                       fordebug
//------------------------------------------------------------------------------------

// ��  ǽ : ���񸡺��η�̤�ɽ������
//
// ����� : �ʤ�

void dict(/*const*/ InDict& indict, const IntStr& intstr, const U_INT4 curpos,
              const W_CHAR_P senten)
{
    for (InMorp_P word = indict.lenpos() ;word->length > 0; word++){
        for (U_INT2 pos = 0; pos+word->length <= curpos; pos++) cerr << "  ";
        cerr << intstr[word->stat] << "/IN" << endl;
    }
}

//------------------------------------------------------------------------------------

void dict(/*const*/ ExDict& exdict, const IntStr& intstr, const U_INT4 curpos,
              const W_CHAR_P senten)
{
    for (ExMorp_P word = exdict.lenpos(); word->length > 0; word++){
        for (U_INT2 pos = 0; pos+word->length <= curpos; pos++) cerr << "  ";
        cerr.write((S_CHAR_P)(senten+curpos+1-word->length), word->length*2);
        cerr << "/" << intstr[word->text] << "/EX" << endl;
    }
}


//====================================================================================
//                       END
//====================================================================================
