//====================================================================================
//                       StochSegText.h
//                            by Shinsuke MORI
//                            Last change : 18 May 1996
//====================================================================================

// ��  ǽ : ��Ψʬ�䥳���ѥ��ˤ��ƥ����Ȥ�����
//
// ��  �� : �ʤ�
//
// ����� : �ǡ�����¤�ϰʲ����̤�
//
//          Pi = 0.95 0.95 0.05 0.05 0.95 0.95 0.95 0.95 0.05 0.05 0.95 0.95 0.95 0.95
//          X  =    BT   ��   ��   ��   ��   ��   BT   ��   ��   ��   ��   ��   BT 


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _StochSegText_h
#define _StochSegText_h

#ifdef DEBUG
#define StochSegText_DEBUG
#endif
//#define StochSegText_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <map>
#include <iomanip>
#include <mystd.h>
#include <Word.h>
#include <SArray.h>


//------------------------------------------------------------------------------------
//                       class StochSegText
//------------------------------------------------------------------------------------

typedef map<WORD, DECIM8> FCACHE;                // ���٥���å���η�

class StochSegText
{

  public:

           SArray   sarray;                       // Suffix Array

                    StochSegText(string&);
    
           DECIM8   Freq(vector<WORD>&);

           DECIM8   Prob(vector<WORD>&);

           DECIM8   _2prob(const WORD&, const WORD&);

           DECIM8   _1prob(const WORD&);

           void     test(const WORD&);

    friend ostream& operator<<(ostream& os, StochSegText&);

  private:

           U_INT4   size;                         // ʸ����

           DECIM8   _0gram;                       // ñ�� 0-gram ����

           DECIM8_P btprob;                       // ñ�춭����Ψ

           FCACHE   fcache;                       // ���٤Υ���å���

           void     ReadBTProb(string&);          // ñ�춭����Ψ���ɤ߹���

};

    
//------------------------------------------------------------------------------------
//                       constructor
//------------------------------------------------------------------------------------

StochSegText::StochSegText(string& stem)
: sarray(stem + ".text", stem + ".sarray"), size(sarray.size)
{
#ifdef StochSegText_DEBUG
    cerr << "StochSegText::StochSegText(U_INT4)" << endl;
#endif

/*
    vector<WORD> word(2);

    WORD w0 = STR2WORD("BT");
    WORD w1 = STR2WORD("���");
//    WORD w0 = STR2WORD("���");
//    WORD w1 = STR2WORD("�ץ饹");
    word[0] = w0;
    word[1] = w1;

    WORD concat = join(WORD(), word);                   // ʸ����(ñ�����Ϣ��)
    cerr << "concat = " << concat << endl;
    sarray.kwic(concat);
    exit(0);
*/

    btprob = new DECIM8[size+1];                  // ñ�춭����Ψ
    ReadBTProb(stem);

    _0gram = 1;                                   // ñ�� 0-gram ����
    for (U_INT4 suff = 1; suff < size; suff++){
        _0gram += btprob[suff];
    }

    cerr << "f() = " << _0gram << endl;
}
        
    
//------------------------------------------------------------------------------------
//                       ReadBTProb
//------------------------------------------------------------------------------------

void StochSegText::ReadBTProb(string& stem)
{
#ifdef StochSegText_DEBUG
    cerr << "StochSegText::ReadBTProb(string&)" << endl;
#endif

    ifstream file((stem+".btprob").c_str());
    if (! file) openfailed(stem+".btprob");
    for (DECIM8_P iter = btprob; iter != btprob+size+1; iter++){
        file.read(S_CHAR_P(&(*iter)), sizeof(DECIM8));
    }
    file.close();
}
        

//------------------------------------------------------------------------------------
//                       Freq
//------------------------------------------------------------------------------------

// ��  ǽ : ñ����δ������٤��֤�
//
// ��  �� : �ʤ�

DECIM8 StochSegText::Freq(vector<WORD>& word)
{
#ifdef StochSegText_DEBUG
    cerr << "StochSegText::Freq(vector<WORD>&)" << endl;
    cerr << "StochSegText::Freq(" << join(W_CHAR(", "), word) << ")" << endl;
#endif

    if (word.size() == 0) return(_0gram);         // ñ�� 0-gram ����
    if ((word.size() == 1) && (word[0] == BTword)) return(sarray.BTFreq);


//---- ���٤�Ĵ�٤���� --------------------------------------------------------------

    vector<WORD>::iterator li = word.begin();     // ��ü�� iterator
    vector<WORD>::iterator ri = word.end();       // ��ü�� iterator (+1)

    if (*li == BTword){                           // ���� BT �ν���
        while ((li+1 < ri) && (*li == BTword)){
            li++;
        }
    }
    if (*(ri-1) == BTword){                       // ��� BT �ν���
        while ((li+1 < ri) && (*(ri-1) == BTword)){
            ri--;
        }
    }
    if ((li+1 == ri) && (*li == BTword)) return(0); // F(BT��BT+) = 0

    WORD wordsequence = join(W_CHAR(", "), word); // ����å���Υ���
#ifdef StochSegText_DEBUG
    cerr << "wordsequence = " << wordsequence << endl;
#endif

    FCACHE::const_iterator iter = fcache.find(wordsequence);

    if (iter != fcache.end()){
#ifdef StochSegText_DEBUG
        cerr << "HIT!" << endl;
#endif
        return((*iter).second);
    }

/*
    if (defined($self->{"Fcache"}{join(" ", @word)})){ //�ϥå���Υ����å�
//       warn "SArrayProb{$word} = ", $SArrayProb{$word}, "\n";
        return($self->{"Fcache"}{join(" ", @word)});
    }
*/

//    WORD concat = concat(word);                   // ʸ����(ñ�����Ϣ��)
    WORD concat = join(WORD(), word);                   // ʸ����(ñ�����Ϣ��)
#ifdef StochSegText_DEBUG
    cerr << "concat = " << concat << endl;
#endif
    U_INT4 length = concat.size();                // ʸ����

    vector<BOOL> mustBT(1+concat.size(), FAUX);   //ñ�춭���Ǥ���٤����ݤ�
    U_INT4 posi = 0;
    mustBT[posi] = VRAI;                          // ��ü��ñ�춭���Ǥ���٤�
    for (U_INT4 i = 0; i < word.size(); i++){
        posi += word[i].size();
        mustBT[posi] = VRAI;                      // i ���ܤ�ñ��ν���ΰ���
    }

#ifdef StochSegText_DEBUG
    cerr << "mustBT = ( ";
    for (vector<BOOL>::iterator it = mustBT.begin(); it != mustBT.end(); it++){
        cerr << *it << " ";
    }
    cerr << ")" << endl;
    sarray.kwic(concat);
#endif

    DECIM8 freq = 0;                              //�ƽи��Ǥ�ñ�춭���� BT �γ�Ψ����
    REGION region = sarray.EqualRange(concat);

    for (vector<U_INT4>::iterator suff = region.first; suff != region.second; suff++){
        DECIM8 prob = 1;                          // ñ�� n-gram �νи���Ψ
        U_INT4 posi = *suff-1;

        for (U_INT4 offset = 0; offset <= length; offset++){

//           printf("BTProb[%d+%d] = %f (%s)\n", $posi, $offset,
//                  $self->BTProb($posi+$offset+1),
//                  $self->sarray->substr($posi+$offset, 2));
            prob *= (mustBT[offset] == VRAI) ?
                btprob[posi+offset+1] : (1-btprob[posi+offset+1]);
        }
        freq += 1*prob;                           // ����νи��δ������٤�û�
    }

//    fcache[wordsequence] = freq;                  // ����å���ؤν񤭹���

    return(freq);
}


//------------------------------------------------------------------------------------
//                       Prob
//------------------------------------------------------------------------------------

// ��  ǽ : ñ�� n-gram ��Ψ P(wn|w1, w2 ... wn-1) ���֤�
//
// ����� : �ʤ�

DECIM8 StochSegText::Prob(vector<WORD>& word)
{
    assert(word.size() > 0);

    vector<WORD> temp = word;
    temp.pop_back();

    return(Freq(word)/Freq(temp));
}


//------------------------------------------------------------------------------------
//                       _1prob
//------------------------------------------------------------------------------------

// ��  ǽ : ñ�� 1-gram ��Ψ P(w1) ���֤�
//
// ����� : �ʤ�

DECIM8 StochSegText::_1prob(const WORD& word)
{
    vector<WORD> temp(1, word);

    return(Freq(temp)/_0gram);
}


//------------------------------------------------------------------------------------
//                       _2prob
//------------------------------------------------------------------------------------

// ��  ǽ : ñ�� 2-gram ��Ψ P(w1|w2) ���֤�
//
// ����� : �ʤ�

DECIM8 StochSegText::_2prob(const WORD& w1, const WORD& w2)
{
#ifdef StochSegText_DEBUG
    cerr << "StochSegText::_2prob(" << w1 << ", " << w2 << ")" << endl;
#endif

    vector<WORD> temp(1, w1);
    DECIM8 f1 = Freq(temp);
#ifdef StochSegText_DEBUG
    cerr << "f(" << temp[0] << ") = " << f1 << endl;
#endif

    temp.push_back(w2);
    DECIM8 f2 = Freq(temp);
#ifdef StochSegText_DEBUG
    cerr << "f(" << temp[0] << ", " << temp[1] << ") = " << f2 << endl;
#endif

    return(f2/f1);
}


//------------------------------------------------------------------------------------
//                       test
//------------------------------------------------------------------------------------

void StochSegText::test(const WORD& word){
#ifdef StochSegText_DEBUG
    cerr << "StochSegText::test(WORD&)" << endl;
#endif

    vector<WORD> temp(1, word);
    cerr << "F(" << word << ") = " << Freq(temp) << endl;

    return;
}


//------------------------------------------------------------------------------------
//                       test
//------------------------------------------------------------------------------------

ostream& operator<<(ostream& os, StochSegText& sstext){

    os << "f(BT) = " << sstext.sarray.BTFreq << endl;
    os << sstext.sarray;

//    os << setprecision(2);
    os << setw(3);                                // �ʤ��������ʤ�
    for (U_INT4 i = 0; i < sstext.size+1; i++){
        os << sstext.btprob[i] << " ";
    }
    os << endl;

    return(os);
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
