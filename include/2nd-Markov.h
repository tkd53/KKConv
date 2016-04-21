//====================================================================================
//                       2nd-Markov.h
//                            by Shinsuke MORI
//                            Last change : 9 June 1995
//====================================================================================

// 機  能 : マルコフモデル
//
// 注意点 : Berkley DB を用いる
//          DB のキャッシュを Map で持つので、意味的には const の関数が、データ的には
//          const ではなくなる。これらの関数にはコメントアウトされた const 宣言を付加


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _Markov_2nd_h
#define _Markov_2nd_h

#ifdef DEBUG
#define Markov_2nd_DEBUG
#endif
//#define Markov_2nd_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#include <db.h>

#include <map>
#include <vector>

#include <math.h>
#include <fcntl.h>
#include <errno.h>
#include <mystd.h>

#include "IntStr.h"


//------------------------------------------------------------------------------------
//                       class Markov
//------------------------------------------------------------------------------------

class Markov_2nd{

  public:

                    Markov_2nd(const string&, const string&);

    inline void     dbbind(const string&);

    inline void     setlambda(const string&);

    inline DECIM8   logP(U_INT4, U_INT4, U_INT4); // const

    inline DECIM8   prob(U_INT4, U_INT4, U_INT4); // const

           void     test(IntStr, U_INT4, U_INT4, U_INT4); // const

    inline U_INT4   _1gram(U_INT4) const;

           U_INT4   _2gram(U_INT4, U_INT4); // const

           U_INT4   _3gram(U_INT4, U_INT4, U_INT4); // const

  private:

           DB*      dbp;                          // DB のポインタ

           DECIM8   L1;                           // 1-gram の補間係数 (2-gram > 0)

           DECIM8   L2;                           // 2-gram の補間係数 (2-gram > 0)

           DECIM8   L3;                           // 3-gram の補間係数 (2-gram > 0)

           DECIM8   L4;                           // 1-gram の補間係数 (2-gram = 0)

           DECIM8   L5;                           // 2-gram の補間係数 (2-gram = 0)

           U_INT4   F0gram;                       // 0-gram 頻度

           U_INT4_P F1gram;                       // 1-gram 頻度のテーブル

           DECIM8_P P1gram;                       // 1-gram 確率のテーブル

    typedef map<vector<U_INT4>, U_INT4, less<vector<U_INT4> > > NCACHE;

    NCACHE          _ngram;                       // n-gram 頻度のキャッシュ

    inline U_INT4   _0gram() const;

           U_INT4   _0gramDB() const;

           U_INT4   _1gramDB(U_INT4) const;

           U_INT4   _2gramDB(U_INT4, U_INT4) const;

           U_INT4   _3gramDB(U_INT4, U_INT4, U_INT4) const;

    inline DECIM8   _1prob(U_INT4) const;

    inline DECIM8   _2prob(U_INT4, U_INT4); // const

    inline DECIM8   _3prob(U_INT4, U_INT4, U_INT4); // const

    inline U_INT4   DBT2U_INT4(const DBT&) const; // DBT から整数への変換

};


//------------------------------------------------------------------------------------
//                       constractor
//------------------------------------------------------------------------------------

Markov_2nd::Markov_2nd(const string& freqfile, const string& lambdafile)
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::Markov_2nd(const string, const string)" << endl;
#endif

    dbbind(freqfile);
    setlambda(lambdafile);

    F0gram = _0gramDB();

    U_INT4 size = 1;
    while (_1gramDB(size) > 0) size++;
    F1gram = new U_INT4[size];
    P1gram = new DECIM8[size];

    for (U_INT4 suff = 0; suff < size; suff++){
        F1gram[suff] = _1gramDB(suff);
        P1gram[suff] = DECIM8(F1gram[suff])/F0gram;
    }
}


//------------------------------------------------------------------------------------
//                       dbbind
//------------------------------------------------------------------------------------

void Markov_2nd::dbbind(const string& filename)
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::dbopen(const string&)" << endl;
#endif

    string suffix = ".db";                        // DB File の Suffix

#ifdef DB185
    dbp = dbopen((filename + suffix).c_str(), 0, S_IRUSR|S_IWUSR, DB_HASH, NULL);
    if (! dbp) openfailed(filename + suffix);
#else // DB185
    S_INT4 ret;
    if ((ret = db_create(&dbp, NULL, 0)) != 0){
        cerr << "db_create: " << db_strerror(ret) << endl;
        exit(1);
    }
    if ((ret = dbp->open(dbp, (filename + suffix).data(), NULL, DB_HASH, 0,
                         0664)) != 0){
        dbp->err(dbp, ret, "%s", (filename + suffix).data());
        exit(1);
    }
#endif // DB185
}


//------------------------------------------------------------------------------------
//                       setlambda
//------------------------------------------------------------------------------------

void Markov_2nd::setlambda(const string& filename)
{
    ifstream lambda(filename.c_str());
    if (! lambda) openfailed(filename);
    lambda >> L1 >> L2 >> L3 >> L4 >> L5;
    lambda.close();
}


//------------------------------------------------------------------------------------
//                       _0gram
//------------------------------------------------------------------------------------

//  機  能 : 0-gram の頻度

inline U_INT4 Markov_2nd::_0gram() const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_0gram()" << endl;
#endif

    return(F0gram);
}


//------------------------------------------------------------------------------------
//                       _1gram
//------------------------------------------------------------------------------------

//  機  能 : 1-gram の頻度

inline U_INT4 Markov_2nd::_1gram(U_INT4 suf1) const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_1gram(U_INT4)" << endl;
#endif

    return(F1gram[suf1]);
}


//------------------------------------------------------------------------------------
//                       _2gram
//------------------------------------------------------------------------------------

//  機  能 : 2-gram の頻度

U_INT4 Markov_2nd::_2gram(U_INT4 suf1, U_INT4 suf2) // const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_2gram(U_INT4, U_INT4)" << endl;
#endif

    vector<U_INT4> mapkey(2, U_INT4(0));
    mapkey[0] = suf1;
    mapkey[1] = suf2;

    NCACHE::const_iterator iter = _ngram.find(mapkey);
    if (iter != _ngram.end()){                    // キャッシュにある場合
        return((*iter).second);
    }

    return(_ngram[mapkey] = _2gramDB(suf1, suf2));
}


//------------------------------------------------------------------------------------
//                       _3gram
//------------------------------------------------------------------------------------

//  機  能 : 3-gram の頻度

U_INT4 Markov_2nd::_3gram(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_3gram(U_INT4, U_INT4, U_INT4)" << endl;
#endif

    vector<U_INT4> mapkey(3, U_INT4(0));
    mapkey[0] = suf1;
    mapkey[1] = suf2;
    mapkey[2] = suf3;

    NCACHE::const_iterator iter = _ngram.find(mapkey);
    if (iter != _ngram.end()){                    // キャッシュにある場合
        return((*iter).second);
    }

    return(_ngram[mapkey] = _3gramDB(suf1, suf2, suf3));
}


//------------------------------------------------------------------------------------
//                       _0gramDB
//------------------------------------------------------------------------------------

//  機  能 : DB の 0-gram の頻度

U_INT4 Markov_2nd::_0gramDB() const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_0gramDB()" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[1] = {0};                     // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*1};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    switch (dbp->get(dbp, &key, &val, 0)){
    case  1:                                      // 登録されていない
        return(0);
    case  0:                                      // 登録されている
        return(DBT2U_INT4(val));
    case -1:                                      // エラー
        perror("Case = -1");
        exit(-1);
    }
#else // DB185
    U_INT4 key2data[1] = {0};                     // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*1};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2U_INT4(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif // DB185
}


//------------------------------------------------------------------------------------
//                       _1gramDB
//------------------------------------------------------------------------------------

//  機  能 : DB の 1-gram の頻度

U_INT4 Markov_2nd::_1gramDB(U_INT4 suf1) const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_1gramDB(U_INT4)DB" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[2] = {suf1, 0};               // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*2};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    switch (dbp->get(dbp, &key, &val, 0)){
    case  1:                                      // 登録されていない
        return(0);
    case  0:                                      // 登録されている
        return(DBT2U_INT4(val));
    case -1:                                      // エラー
        exit(-1);
    }
#else
    U_INT4 key2data[2] = {suf1, 0};               // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*2};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2U_INT4(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif
}


//------------------------------------------------------------------------------------
//                       _2gramDB
//------------------------------------------------------------------------------------

//  機  能 : 2-gram の頻度

U_INT4 Markov_2nd::_2gramDB(U_INT4 suf1, U_INT4 suf2) const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_2gramDB(U_INT4, U_INT4)" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[3] = {suf1, suf2, 0};         // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*3};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    switch (dbp->get(dbp, &key, &val, 0)){
    case 1:                                       // 登録されていない
        return(0);
    case 0:                                       // 登録されている
        return(DBT2U_INT4(val));
    case -1:                                      // エラー
        exit(-1);
    }
#else
    U_INT4 key2data[3] = {suf1, suf2, 0};         // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*3};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2U_INT4(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif
}


//------------------------------------------------------------------------------------
//                       _3gramDB
//------------------------------------------------------------------------------------

//  機  能 : 3-gram の頻度

U_INT4 Markov_2nd::_3gramDB(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_3gramDB(U_INT4, U_INT4, U_INT4)" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[4] = {suf1, suf2, suf3, 0};   // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*4};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    switch (dbp->get(dbp, &key, &val, 0)){
    case 1:                                       // 登録されていない
        return(0);
    case 0:                                       // 登録されている
        return(DBT2U_INT4(val));
    case -1:                                      // エラー
        exit(-1);
    }
#else
    U_INT4 key2data[4] = {suf1, suf2, suf3, 0};   // DB の検索キーを生成するための変数
    DBT key = {key2data, sizeof(U_INT4)*4};       // DB の検索キー
    DBT val;                                      // DB の検索結果

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2U_INT4(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif
}


//------------------------------------------------------------------------------------
//                       logP
//------------------------------------------------------------------------------------

// 機  能 : 補間した遷移確率の負対数値を返す。

inline DECIM8 Markov_2nd::logP(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::logP(U_INT4, U_INT4, U_INT4)" << endl;
#endif

    return(-log(prob(suf1, suf2, suf3)));
}


//------------------------------------------------------------------------------------
//                       prob
//------------------------------------------------------------------------------------

// 機  能 : 補間した遷移確率を返す。

inline DECIM8 Markov_2nd::prob(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::prob(U_INT4, U_INT4, U_INT4)" << endl;
#endif

    if (_2gram(suf1, suf2) > 0){
        return(L1*_1prob(suf3)+L2*_2prob(suf2, suf3)+L3*_3prob(suf1, suf2, suf3));
    }else{
        return(L4*_1prob(suf3)+L5*_2prob(suf2, suf3));
    }
}


//------------------------------------------------------------------------------------
//                       _1prob
//------------------------------------------------------------------------------------

// 機  能 : 0 重マルコフモデルによる遷移確率を返す。

inline DECIM8 Markov_2nd::_1prob(U_INT4 suf3) const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_1prob(U_INT4)" << endl;
#endif

    return(P1gram[suf3]);
}


//------------------------------------------------------------------------------------
//                       _2prob
//------------------------------------------------------------------------------------

// 機  能 : 1 重マルコフモデルによる遷移確率を返す。

inline DECIM8 Markov_2nd::_2prob(U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_2prob(U_INT4, U_INT4)" << endl;
#endif

    return((DECIM8)_2gram(suf2, suf3)/(DECIM8)_1gram(suf2));
}


//------------------------------------------------------------------------------------
//                       _3prob
//------------------------------------------------------------------------------------

// 機  能 : 2 重マルコフモデルによる遷移確率を返す。

inline DECIM8 Markov_2nd::_3prob(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::_3prob(U_INT4, U_INT4)" << endl;
#endif

    return((DECIM8)_3gram(suf1, suf2, suf3)/(DECIM8)_2gram(suf1, suf2));
}


//------------------------------------------------------------------------------------
//                       DBT2U_INT4
//------------------------------------------------------------------------------------

inline U_INT4 Markov_2nd::DBT2U_INT4(const DBT& val) const
{
#ifdef Markov_2nd_DEBUG
    cerr << "Markov_2nd::DBT2U_INT4(const DBT&)" << endl;
#endif

    U_INT4 temp = 0;
    for (U_INT4 i = 0; i < val.size; i++){
        temp *= 10;
        temp += (U_INT4)(((U_INT1_P)val.data)[i]-'0');
    }
    return(temp);
}


//------------------------------------------------------------------------------------
//                       test
//------------------------------------------------------------------------------------

void Markov_2nd::test(IntStr intstr, U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) // const
{
    cout << "Freq(" << intstr[suf1] << " " << intstr[suf2] << " " << intstr[suf3]
         << ") = " << _3gram(suf1, suf2, suf3) << endl;
    cout << "Freq(" << intstr[suf1] << " " << intstr[suf2] << ") = "
         << _2gram(suf1, suf2) << endl;
    cout << "Freq(" << intstr[suf2] << " " << intstr[suf3] << ") = "
         << _2gram(suf2, suf3) << endl;
    cout << "Freq(" << intstr[suf1] << ") = " << _1gram(suf1) << endl;
    cout << "Freq(" << intstr[suf2] << ") = " << _1gram(suf2) << endl;
    cout << "Freq(" << intstr[suf3] << ") = " << _1gram(suf3) << endl;
    cout << "Freq() = " << _0gram() << endl;
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
