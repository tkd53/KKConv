//====================================================================================
//                       StochSegText.h
//                            by Shinsuke MORI
//                            Last change : 18 May 1996
//====================================================================================

// 機  能 : 確率分割コーパスによるテキストの統計
//
// 実  例 : なし
//
// 注意点 : データ構造は以下の通り
//
//          Pi = 0.95 0.95 0.05 0.05 0.95 0.95 0.95 0.95 0.05 0.05 0.95 0.95 0.95 0.95
//          X  =    BT   攻   め   こ   む   。   BT   受   け   切   る   。   BT 


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

typedef map<WORD, DECIM8> FCACHE;                // 頻度キャッシュの型

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

           U_INT4   size;                         // 文字数

           DECIM8   _0gram;                       // 単語 0-gram 頻度

           DECIM8_P btprob;                       // 単語境界確率

           FCACHE   fcache;                       // 頻度のキャッシュ

           void     ReadBTProb(string&);          // 単語境界確率の読み込み

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
    WORD w1 = STR2WORD("ワん");
//    WORD w0 = STR2WORD("ワんズ");
//    WORD w1 = STR2WORD("プラス");
    word[0] = w0;
    word[1] = w1;

    WORD concat = join(WORD(), word);                   // 文字列(単語列の連接)
    cerr << "concat = " << concat << endl;
    sarray.kwic(concat);
    exit(0);
*/

    btprob = new DECIM8[size+1];                  // 単語境界確率
    ReadBTProb(stem);

    _0gram = 1;                                   // 単語 0-gram 頻度
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

// 機  能 : 単語列の期待頻度を返す
//
// 注  意 : なし

DECIM8 StochSegText::Freq(vector<WORD>& word)
{
#ifdef StochSegText_DEBUG
    cerr << "StochSegText::Freq(vector<WORD>&)" << endl;
    cerr << "StochSegText::Freq(" << join(W_CHAR(", "), word) << ")" << endl;
#endif

    if (word.size() == 0) return(_0gram);         // 単語 0-gram 頻度
    if ((word.size() == 1) && (word[0] == BTword)) return(sarray.BTFreq);


//---- 頻度を調べる準備 --------------------------------------------------------------

    vector<WORD>::iterator li = word.begin();     // 左端の iterator
    vector<WORD>::iterator ri = word.end();       // 右端の iterator (+1)

    if (*li == BTword){                           // 前の BT の縮退
        while ((li+1 < ri) && (*li == BTword)){
            li++;
        }
    }
    if (*(ri-1) == BTword){                       // 後の BT の縮退
        while ((li+1 < ri) && (*(ri-1) == BTword)){
            ri--;
        }
    }
    if ((li+1 == ri) && (*li == BTword)) return(0); // F(BT・BT+) = 0

    WORD wordsequence = join(W_CHAR(", "), word); // キャッシュのキー
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
    if (defined($self->{"Fcache"}{join(" ", @word)})){ //ハッシュのチェック
//       warn "SArrayProb{$word} = ", $SArrayProb{$word}, "\n";
        return($self->{"Fcache"}{join(" ", @word)});
    }
*/

//    WORD concat = concat(word);                   // 文字列(単語列の連接)
    WORD concat = join(WORD(), word);                   // 文字列(単語列の連接)
#ifdef StochSegText_DEBUG
    cerr << "concat = " << concat << endl;
#endif
    U_INT4 length = concat.size();                // 文字数

    vector<BOOL> mustBT(1+concat.size(), FAUX);   //単語境界であるべきか否か
    U_INT4 posi = 0;
    mustBT[posi] = VRAI;                          // 左端は単語境界であるべき
    for (U_INT4 i = 0; i < word.size(); i++){
        posi += word[i].size();
        mustBT[posi] = VRAI;                      // i 番目の単語の終りの位置
    }

#ifdef StochSegText_DEBUG
    cerr << "mustBT = ( ";
    for (vector<BOOL>::iterator it = mustBT.begin(); it != mustBT.end(); it++){
        cerr << *it << " ";
    }
    cerr << ")" << endl;
    sarray.kwic(concat);
#endif

    DECIM8 freq = 0;                              //各出現での単語境界が BT の確率の和
    REGION region = sarray.EqualRange(concat);

    for (vector<U_INT4>::iterator suff = region.first; suff != region.second; suff++){
        DECIM8 prob = 1;                          // 単語 n-gram の出現確率
        U_INT4 posi = *suff-1;

        for (U_INT4 offset = 0; offset <= length; offset++){

//           printf("BTProb[%d+%d] = %f (%s)\n", $posi, $offset,
//                  $self->BTProb($posi+$offset+1),
//                  $self->sarray->substr($posi+$offset, 2));
            prob *= (mustBT[offset] == VRAI) ?
                btprob[posi+offset+1] : (1-btprob[posi+offset+1]);
        }
        freq += 1*prob;                           // １回の出現の期待頻度を加算
    }

//    fcache[wordsequence] = freq;                  // キャッシュへの書き込み

    return(freq);
}


//------------------------------------------------------------------------------------
//                       Prob
//------------------------------------------------------------------------------------

// 機  能 : 単語 n-gram 確率 P(wn|w1, w2 ... wn-1) を返す
//
// 注意点 : なし

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

// 機  能 : 単語 1-gram 確率 P(w1) を返す
//
// 注意点 : なし

DECIM8 StochSegText::_1prob(const WORD& word)
{
    vector<WORD> temp(1, word);

    return(Freq(temp)/_0gram);
}


//------------------------------------------------------------------------------------
//                       _2prob
//------------------------------------------------------------------------------------

// 機  能 : 単語 2-gram 確率 P(w1|w2) を返す
//
// 注意点 : なし

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
    os << setw(3);                                // なぜか効かない
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
