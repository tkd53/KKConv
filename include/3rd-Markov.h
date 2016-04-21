//====================================================================================
//                       3rd-Markov.h
//                            by Shinsuke MORI
//                            Last change : 9 June 1995
//====================================================================================

// ��  ǽ : �ޥ륳�ե��ǥ�
//
// ������ : Berkley DB ���Ѥ���
//          DB �Υ����å����� Map �ǻ��ĤΤǡ���̣Ū�ˤ� const �δؿ������ǡ���Ū�ˤ�
//          const �ǤϤʤ��ʤ롣�������δؿ��ˤϥ������ȥ����Ȥ��줿 const �������ղ�


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _Markov_3rd_h
#define _Markov_3rd_h

#ifdef DEBUG
#define Markov_3rd_DEBUG
#endif
//#define Markov_3rd_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

#define DB185

#ifdef DB185
#include <db4/db_185.h>
//#include <db_185.h>
#else // DB185
#include <db.h>
#endif // DB185

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

class Markov_3rd{

  public:

                    Markov_3rd(const string&, const string&);

    inline void     dbbind(const string&);

    inline void     setlambda(const string&);

    inline DECIM8   logP(U_INT4, U_INT4, U_INT4, U_INT4); // const

    inline DECIM8   prob(U_INT4, U_INT4, U_INT4, U_INT4); // const

           void     test(IntStr, U_INT4, U_INT4, U_INT4, U_INT4); // const

    inline U_INT4   _1gram(U_INT4) const;

           U_INT4   _2gram(U_INT4, U_INT4); // const

           U_INT4   _3gram(U_INT4, U_INT4, U_INT4); // const

           U_INT4   _4gram(U_INT4, U_INT4, U_INT4, U_INT4); // const

  private:

           DB*      dbp;                          // DB �Υݥ�����

           DECIM8   L1;                           // 1-gram �����ַ��� (2-gram > 0)

           DECIM8   L2;                           // 2-gram �����ַ��� (2-gram > 0)

           DECIM8   L3;                           // 3-gram �����ַ��� (2-gram > 0)

           DECIM8   L4;                           // 1-gram �����ַ��� (2-gram = 0)

           DECIM8   L5;                           // 2-gram �����ַ��� (2-gram = 0)

           DECIM8   L6;                           // 2-gram �����ַ��� (3-gram = 0)

           DECIM8   L7;                           // 3-gram �����ַ��� (3-gram = 0)

           DECIM8   L8;                           // 1-gram �����ַ��� (2-gram = 0)

           DECIM8   L9;                           // 2-gram �����ַ��� (2-gram = 0)

           U_INT4   F0gram;                       // 0-gram ����

           U_INT4_P F1gram;                       // 1-gram ���٤Υơ��֥�

           DECIM8_P P1gram;                       // 1-gram ��Ψ�Υơ��֥�

    typedef map<vector<U_INT4>, U_INT4, less<vector<U_INT4> > > NCACHE;

    NCACHE          _ngram;                       // n-gram ���٤Υ����å���

    inline U_INT4   _0gram() const;

           U_INT4   _0gramDB() const;

           U_INT4   _1gramDB(U_INT4) const;

           U_INT4   _2gramDB(U_INT4, U_INT4) const;

           U_INT4   _3gramDB(U_INT4, U_INT4, U_INT4) const;

           U_INT4   _4gramDB(U_INT4, U_INT4, U_INT4, U_INT4) const;

    inline DECIM8   _1prob(U_INT4) const;

    inline DECIM8   _2prob(U_INT4, U_INT4); // const

    inline DECIM8   _3prob(U_INT4, U_INT4, U_INT4); // const

    inline DECIM8   _4prob(U_INT4, U_INT4, U_INT4, U_INT4); // const

    inline U_INT4   DBT2U_INT4(const DBT&) const; // DBT ���������ؤ��Ѵ�

};


//------------------------------------------------------------------------------------
//                       constractor
//------------------------------------------------------------------------------------

Markov_3rd::Markov_3rd(const string& freqfile, const string& lambdafile)
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::Markov_3rd(const string, const string)" << endl;
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

void Markov_3rd::dbbind(const string& filename)
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::dbopen(const string&)" << endl;
#endif

    string suffix = ".db";                        // DB File �� Suffix

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

void Markov_3rd::setlambda(const string& filename)
{
    ifstream lambda(filename.c_str());
    if (! lambda) openfailed(filename);
    lambda >> L1 >> L2 >> L3 >> L4 >> L5 >> L6 >> L7 >> L8 >> L9;
    lambda.close();
}


//------------------------------------------------------------------------------------
//                       _0gram
//------------------------------------------------------------------------------------

//  ��  ǽ : 0-gram ������

inline U_INT4 Markov_3rd::_0gram() const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_0gram()" << endl;
#endif

    return(F0gram);
}


//------------------------------------------------------------------------------------
//                       _1gram
//------------------------------------------------------------------------------------

//  ��  ǽ : 1-gram ������

inline U_INT4 Markov_3rd::_1gram(U_INT4 suf1) const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_1gram(U_INT4)" << endl;
#endif

    return(F1gram[suf1]);
}


//------------------------------------------------------------------------------------
//                       _2gram
//------------------------------------------------------------------------------------

//  ��  ǽ : 2-gram ������

U_INT4 Markov_3rd::_2gram(U_INT4 suf1, U_INT4 suf2) // const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_2gram(U_INT4, U_INT4)" << endl;
#endif

    vector<U_INT4> mapkey(2, U_INT4(0));
    mapkey[0] = suf1;
    mapkey[1] = suf2;

    NCACHE::const_iterator iter = _ngram.find(mapkey);
    if (iter != _ngram.end()){                    // �����å����ˤ�������
        return((*iter).second);
    }

    return(_ngram[mapkey] = _2gramDB(suf1, suf2));
}


//------------------------------------------------------------------------------------
//                       _3gram
//------------------------------------------------------------------------------------

//  ��  ǽ : 3-gram ������

U_INT4 Markov_3rd::_3gram(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_3gram(U_INT4, U_INT4, U_INT4)" << endl;
#endif

    vector<U_INT4> mapkey(3, U_INT4(0));
    mapkey[0] = suf1;
    mapkey[1] = suf2;
    mapkey[2] = suf3;

    NCACHE::const_iterator iter = _ngram.find(mapkey);
    if (iter != _ngram.end()){                    // �����å����ˤ�������
        return((*iter).second);
    }

    return(_ngram[mapkey] = _3gramDB(suf1, suf2, suf3));
}


//------------------------------------------------------------------------------------
//                       _4gram
//------------------------------------------------------------------------------------

//  ��  ǽ : 4-gram ������

U_INT4 Markov_3rd::_4gram(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3, U_INT4 suf4)
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_4gram(U_INT4, U_INT4, U_INT4, U_INT4)" << endl;
#endif

    vector<U_INT4> mapkey(4, U_INT4(0));
    mapkey[0] = suf1;
    mapkey[1] = suf2;
    mapkey[2] = suf3;
    mapkey[3] = suf4;

    NCACHE::const_iterator iter = _ngram.find(mapkey);
    if (iter != _ngram.end()){                    // �����å����ˤ�������
        return((*iter).second);
    }

    return(_ngram[mapkey] = _4gramDB(suf1, suf2, suf3, suf4));
}


//------------------------------------------------------------------------------------
//                       _0gramDB
//------------------------------------------------------------------------------------

//  ��  ǽ : DB �� 0-gram ������

U_INT4 Markov_3rd::_0gramDB() const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_0gramDB()" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[1] = {0};                     // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*1};       // DB �θ�������
    DBT val;                                      // DB �θ�������
    
    switch (dbp->get(dbp, &key, &val, 0)){
    case  1:                                      // ��Ͽ�����Ƥ��ʤ�
        return(0);
    case  0:                                      // ��Ͽ�����Ƥ���
        return(DBT2U_INT4(val));
    case -1:                                      // ���顼
        perror("Case = -1");
        exit(-1);
    }
#else // DB185
    U_INT4 key2data[1] = {0};                     // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*1};       // DB �θ�������
    DBT val;                                      // DB �θ�������

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

//  ��  ǽ : DB �� 1-gram ������

U_INT4 Markov_3rd::_1gramDB(U_INT4 suf1) const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_1gramDB(U_INT4)DB" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[2] = {suf1, 0};               // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*2};       // DB �θ�������
    DBT val;                                      // DB �θ�������
    
    switch (dbp->get(dbp, &key, &val, 0)){
    case  1:                                      // ��Ͽ�����Ƥ��ʤ�
        return(0);
    case  0:                                      // ��Ͽ�����Ƥ���
        return(DBT2U_INT4(val));
    case -1:                                      // ���顼
        exit(-1);
    }
#else
    U_INT4 key2data[2] = {suf1, 0};               // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*2};       // DB �θ�������
    DBT val;                                      // DB �θ�������

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

//  ��  ǽ : 2-gram ������

U_INT4 Markov_3rd::_2gramDB(U_INT4 suf1, U_INT4 suf2) const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_2gramDB(U_INT4, U_INT4)" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[3] = {suf1, suf2, 0};         // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*3};       // DB �θ�������
    DBT val;                                      // DB �θ�������

    switch (dbp->get(dbp, &key, &val, 0)){
    case 1:                                       // ��Ͽ�����Ƥ��ʤ�
        return(0);
    case 0:                                       // ��Ͽ�����Ƥ���
        return(DBT2U_INT4(val));
    case -1:                                      // ���顼
        exit(-1);
    }
#else
    U_INT4 key2data[3] = {suf1, suf2, 0};         // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*3};       // DB �θ�������
    DBT val;                                      // DB �θ�������

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

//  ��  ǽ : 3-gram ������

U_INT4 Markov_3rd::_3gramDB(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_3gramDB(U_INT4, U_INT4, U_INT4)" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[4] = {suf1, suf2, suf3, 0};   // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*4};       // DB �θ�������
    DBT val;                                      // DB �θ�������

    switch (dbp->get(dbp, &key, &val, 0)){
    case 1:                                       // ��Ͽ�����Ƥ��ʤ�
        return(0);
    case 0:                                       // ��Ͽ�����Ƥ���
        return(DBT2U_INT4(val));
    case -1:                                      // ���顼
        exit(-1);
    }
#else
    U_INT4 key2data[4] = {suf1, suf2, suf3, 0};   // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*4};       // DB �θ�������
    DBT val;                                      // DB �θ�������

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2U_INT4(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif
}


//------------------------------------------------------------------------------------
//                       _4gramDB
//------------------------------------------------------------------------------------

//  ��  ǽ : 4-gram ������

U_INT4 Markov_3rd::_4gramDB(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3, U_INT4 suf4) const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_4gramDB(U_INT4, U_INT4, U_INT4, U_INT4)" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[5] = {suf1, suf2, suf3, suf4, 0};
                                                  // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*5};       // DB �θ�������
    DBT val;                                      // DB �θ�������

    switch (dbp->get(dbp, &key, &val, 0)){
    case 1:                                       // ��Ͽ�����Ƥ��ʤ�
        return(0);
    case 0:                                       // ��Ͽ�����Ƥ���
        return(DBT2U_INT4(val));
    case -1:                                      // ���顼
        exit(-1);
    }
#else
    U_INT4 key2data[5] = {suf1, suf2, suf3, suf4, 0};
                                                  // DB �θ����������������뤿�����ѿ�
    DBT key = {key2data, sizeof(U_INT4)*5};       // DB �θ�������
    DBT val;                                      // DB �θ�������

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

// ��  ǽ : ���֤������ܳ�Ψ�����п��ͤ��֤���

inline DECIM8 Markov_3rd::logP(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3, U_INT4 suf4)
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::logP(U_INT4, U_INT4, U_INT4, U_INT4)" << endl;
#endif

    return(-log(prob(suf1, suf2, suf3, suf4)));
}


//------------------------------------------------------------------------------------
//                       prob
//------------------------------------------------------------------------------------

// ��  ǽ : ���֤������ܳ�Ψ���֤���

inline DECIM8 Markov_3rd::prob(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3, U_INT4 suf4)
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::prob(U_INT4, U_INT4, U_INT4, U_INT4)" << endl;
#endif

    if (_3gram(suf1, suf2, suf3) > 0){
        return(L1*_1prob(suf4)+L2*_2prob(suf3, suf4)+L3*_3prob(suf2, suf3, suf4)
              +L4*_4prob(suf1, suf2, suf3, suf4));
    }else if (_2gram(suf2, suf3) > 0){
        return(L5*_1prob(suf4)+L6*_2prob(suf3, suf4)+L7*_3prob(suf2, suf3, suf4));
    }else{
        return(L8*_1prob(suf4)+L9*_2prob(suf3, suf4));
    }
}


//------------------------------------------------------------------------------------
//                       _1prob
//------------------------------------------------------------------------------------

// ��  ǽ : 0 �ťޥ륳�ե��ǥ��ˤ������ܳ�Ψ���֤���

inline DECIM8 Markov_3rd::_1prob(U_INT4 suf3) const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_1prob(U_INT4)" << endl;
#endif

    return(P1gram[suf3]);
}


//------------------------------------------------------------------------------------
//                       _2prob
//------------------------------------------------------------------------------------

// ��  ǽ : 1 �ťޥ륳�ե��ǥ��ˤ������ܳ�Ψ���֤���

inline DECIM8 Markov_3rd::_2prob(U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_2prob(U_INT4, U_INT4)" << endl;
#endif

    return((DECIM8)_2gram(suf2, suf3)/(DECIM8)_1gram(suf2));
}


//------------------------------------------------------------------------------------
//                       _3prob
//------------------------------------------------------------------------------------

// ��  ǽ : 2 �ťޥ륳�ե��ǥ��ˤ������ܳ�Ψ���֤���

inline DECIM8 Markov_3rd::_3prob(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3) // const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_3prob(U_INT4, U_INT4)" << endl;
#endif

    return((DECIM8)_3gram(suf1, suf2, suf3)/(DECIM8)_2gram(suf1, suf2));
}


//------------------------------------------------------------------------------------
//                       _4prob
//------------------------------------------------------------------------------------

// ��  ǽ : 2 �ťޥ륳�ե��ǥ��ˤ������ܳ�Ψ���֤���

inline DECIM8 Markov_3rd::_4prob(U_INT4 suf1, U_INT4 suf2, U_INT4 suf3, U_INT4 suf4)
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::_4prob(U_INT4, U_INT4, U_INT4, U_INT4)" << endl;
#endif

    return((DECIM8)_4gram(suf1, suf2, suf3, suf4)/(DECIM8)_3gram(suf1, suf2, suf3));
}


//------------------------------------------------------------------------------------
//                       DBT2U_INT4
//------------------------------------------------------------------------------------

inline U_INT4 Markov_3rd::DBT2U_INT4(const DBT& val) const
{
#ifdef Markov_3rd_DEBUG
    cerr << "Markov_3rd::DBT2U_INT4(const DBT&)" << endl;
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

void Markov_3rd::test(IntStr intstr, U_INT4 suf1, U_INT4 suf2, U_INT4 suf3,
                      U_INT4 suf4) // const
{
    cout << "Freq(" << intstr[suf1] << " " << intstr[suf2] << " " << intstr[suf3]
         << " " << intstr[suf4] << ") = " << _4gram(suf1, suf2, suf3, suf4) << endl;
    cout << "Freq(" << intstr[suf1] << " " << intstr[suf2] << " " << intstr[suf3]
         << ") = " << _3gram(suf1, suf2, suf3) << endl;
    cout << "Freq(" << intstr[suf2] << " " << intstr[suf3] << " " << intstr[suf4]
         << ") = " << _3gram(suf2, suf3, suf4) << endl;
    cout << "Freq(" << intstr[suf1] << " " << intstr[suf2] << ") = "
         << _2gram(suf1, suf2) << endl;
    cout << "Freq(" << intstr[suf2] << " " << intstr[suf3] << ") = "
         << _2gram(suf2, suf3) << endl;
    cout << "Freq(" << intstr[suf3] << " " << intstr[suf4] << ") = "
         << _2gram(suf3, suf4) << endl;
    cout << "Freq(" << intstr[suf1] << ") = " << _1gram(suf1) << endl;
    cout << "Freq(" << intstr[suf2] << ") = " << _1gram(suf2) << endl;
    cout << "Freq(" << intstr[suf3] << ") = " << _1gram(suf3) << endl;
    cout << "Freq(" << intstr[suf4] << ") = " << _1gram(suf4) << endl;
    cout << "Freq() = " << _0gram() << endl;
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
