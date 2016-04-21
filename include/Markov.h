//====================================================================================
//                       Decim8Markov.h
//                            by Shinsuke MORI
//                            Last change : 9 June 1995
//====================================================================================

// ù??ù??  ?? : ù????ù??ù????ù??ù????ù??
//
// ù??ù??ù??ù??ù??ù?? : Berkley DB ù??ù??ù????ù??ù??ù??


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _Markov_h
#define _Markov_h

#ifdef DEBUG
#define Markov_DEBUG
#endif
//#define Markov_DEBUG


//------------------------------------------------------------------------------------
//                       include
//------------------------------------------------------------------------------------

//#include <db.h>
#include <db_cxx.h>
static DBT dbt_initializer;
/*
#define S_IRWXU 00700
#define S_IRUSR 00400
#define S_IWUSR 00200
#define S_IXUSR 00100
*/

#include <math.h>
#include <fcntl.h>
#include <errno.h>
#include <mystd.h>

#include "IntStr.h"


//------------------------------------------------------------------------------------
//                       class Markov
//------------------------------------------------------------------------------------

class Markov{

  public:

                  Markov(DECIM8 L1 = 0.5, DECIM8 L2 = 0.5);
                  Markov(const string&, DECIM8, DECIM8);

                  Markov(const string&, const string&);

    inline void   dbbind(const string&);

    inline void   setlambda(DECIM8, DECIM8);

    inline void   setlambda(const string&);

    inline DECIM8 logP(U_INT4, U_INT4) const;

    inline DECIM8 prob(U_INT4, U_INT4) const;

           void   test(IntStr, U_INT4, U_INT4) const;

           DECIM8 _1gram(U_INT4) const;

           DECIM8 _2gram(U_INT4, U_INT4) const;

    inline DECIM8 _1prob(U_INT4) const;

    inline DECIM8 _2prob(U_INT4, U_INT4) const;

  private:

           DB*    dbp;                            // DB ù??????ù??ù??ù??ù??ù??

           DECIM8 L1;                             // 1-gram ù??ù??ù??ù??ù????ù??ù??ù??

           DECIM8 L2;                             // 2-gram ù??ù??ù??ù??ù????ù??ù??ù??

           DECIM8 _0gram() const;

//           U_INT4 _1gram(U_INT4) const;           // Used in VTable of Clst

    inline DECIM8 DBT2DECIM8(const DBT&) const;   // DBT ù??ù??ù??ù??ù??ù??ù??ù??ù????ù??ù????ù??

};


//------------------------------------------------------------------------------------
//                       constractor
//------------------------------------------------------------------------------------

Markov::Markov(DECIM8 L1, DECIM8 L2)
: L1(L1/(L1+L2)), L2(L2/(L1+L2))
{
#ifdef Markov_DEBUG
    cerr << "Markov::Markov()" << endl;
#endif

    dbp = NULL;
}

Markov::Markov(const string& freqfile, DECIM8 L1 = 0.5, DECIM8 L2 = 0.5)
//: L1(L1/(L1+L2)), L2(L2/(L1+L2))
: L1(L1), L2(L2)
{
#ifdef Markov_DEBUG
    cerr << "Markov::Markov(freqfile = " << freqfile << ")\n";
#endif

    dbbind(freqfile);
}

Markov::Markov(const string& freqfile, const string& lambdafile)
{
#ifdef Markov_DEBUG
    cerr << "Markov::Markov(const string, const string)" << endl;
#endif

    dbbind(freqfile);
    setlambda(lambdafile);
}


//------------------------------------------------------------------------------------
//                       dbbind
//------------------------------------------------------------------------------------

void Markov::dbbind(const string& filename)
{
#ifdef Markov_DEBUG
    cerr << "Markov::dbopen(const string&)" << endl;
#endif

    string suffix = ".db";                        // DB File ù??ù?? Suffix

#ifdef DB185
    dbp = dbopen((filename + suffix).c_str(), 0, 0, DB_HASH, NULL);
    if (! dbp) openfailed(filename + suffix);
#else // DB185

//DB C++
//    DB db();
//    db.open(NULL, (filename + suffix).data(), NULL,
//                         DB_HASH,
//                         0,
//            0664)) != 0);
    S_INT4 ret;

    if ((ret = db_create(&dbp, NULL, 0)) != 0){
        cerr << "db_create: " << db_strerror(ret) << endl;
        exit (1);
    }
    cerr << "OK1" << endl;
    if ((ret = dbp->open(dbp, NULL, (filename + suffix).data(), NULL,
                         DB_HASH,
                         0,
                         0664)) != 0) {
        dbp->err(dbp, ret, "%s", (filename + suffix).data());
        exit(1);
    }
    cerr << "OK2" << endl;
#endif // DB185
}


//------------------------------------------------------------------------------------
//                       lambda
//------------------------------------------------------------------------------------

void Markov::setlambda(DECIM8 l1, DECIM8 l2)
{
    L1 = l1/(l1+l2);
    L2 = l2/(l1+l2);
}

void Markov::setlambda(const string& filename)
{
    ifstream lambda(filename.c_str());
    if (! lambda) openfailed(filename);
    lambda >> L1 >> L2;
//    cerr << "(L1, L2) = (" << L1 << ", " << L2 << ")" << endl;
    lambda.close();
}


//------------------------------------------------------------------------------------
//                       _0gram
//------------------------------------------------------------------------------------

//  ù??ù??  ?? : 0-gram ù??ù??ù??ù??ù??ù??

DECIM8 Markov::_0gram() const
{
#ifdef Markov_DEBUG
    cerr << "Markov::_0gram()" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[1] = {0};                     // DB ù????ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù????ù??
    DBT key = {key2data, sizeof(U_INT4)*1};       // DB ù????ù??ù??ù??ù??ù??ù??ù??
//    DBT key = {NULL, 0};                          // DB ù????ù??ù??ù??ù??ù??ù??ù??
    DBT val =  dbt_initializer;                                      // DB ù????ù??ù??ù??ù??ù??ù??ù??

    switch (dbp->get(dbp, &key, &val, 0)){
    case  1:                                      // ù??ù????ù??ù??ù??ù??ù????ù??ù????ù??
        return(0);
    case  0:                                      // ù??ù????ù??ù??ù??ù??ù????ù??ù??ù??
        return(DBT2DECIM8(val));
    case -1:                                      // ù??ù??ù????
        perror("Case = -1");
        exit(-1);
    }
#else // DB185
    U_INT4 key2data[1] = {0};                     // DB ù????ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù????ù??
    DBT key = {key2data, sizeof(U_INT4)*1};       // DB ù????ù??ù??ù??ù??ù??ù??ù??
    DBT val = dbt_initializer;                                      // DB ù????ù??ù??ù??ù??ù??ù??ù??

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2DECIM8(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif // DB185
}


//------------------------------------------------------------------------------------
//                       _1gram
//------------------------------------------------------------------------------------

//  ù??ù??  ?? : 1-gram ù??ù??ù??ù??ù??ù??

DECIM8 Markov::_1gram(U_INT4 suf1) const
{
#ifdef Markov_DEBUG
    cerr << "Markov::_1gram(U_INT4)" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[2] = {suf1, 0};               // DB ù????ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù????ù??
    DBT key = {key2data, sizeof(U_INT4)*2};       // DB ù????ù??ù??ù??ù??ù??ù??ù??
    DBT val = dbt_initializer;                                      // DB ù????ù??ù??ù??ù??ù??ù??ù??

    switch (dbp->get(dbp, &key, &val, 0)){
    case  1:                                      // ù??ù????ù??ù??ù??ù??ù????ù??ù????ù??
        return(0);
    case  0:                                      // ù??ù????ù??ù??ù??ù??ù????ù??ù??ù??
        return(DBT2DECIM8(val));
    case -1:                                      // ù??ù??ù????
        exit(-1);
    }
#else
    U_INT4 key2data[2] = {suf1, 0};               // DB ù????ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù????ù??
    DBT key = {key2data, sizeof(U_INT4)*2};       // DB ù????ù??ù??ù??ù??ù??ù??ù??
    DBT val = dbt_initializer;                                      // DB ù????ù??ù??ù??ù??ù??ù??ù??

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2DECIM8(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif
}


//------------------------------------------------------------------------------------
//                       _2gram
//------------------------------------------------------------------------------------

//  ù??ù??  ?? : 2-gram ù??ù??ù??ù??ù??ù??

DECIM8 Markov::_2gram(U_INT4 suf1, U_INT4 suf2) const
{
#ifdef Markov_DEBUG
    cerr << "Markov::_2gram(U_INT4, U_INT4)" << endl;
#endif

#ifdef DB185
    U_INT4 key2data[3] = {suf1, suf2, 0};         // DB ù????ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù????ù??
    DBT key = {key2data, sizeof(U_INT4)*3};       // DB ù????ù??ù??ù??ù??ù??ù??ù??
    DBT val = dbt_initializer;                                      // DB ù????ù??ù??ù??ù??ù??ù??ù??

    switch (dbp->get(dbp, &key, &val, 0)){
    case 1:                                       // ù??ù????ù??ù??ù??ù??ù????ù??ù????ù??
        return(0);
    case 0:                                       // ù??ù????ù??ù??ù??ù??ù????ù??ù??ù??
        return(DBT2DECIM8(val));
    case -1:                                      // ù??ù??ù????
        exit(-1);
    }
#else
    U_INT4 key2data[3] = {suf1, suf2, 0};         // DB ù????ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù??ù????ù??
    DBT key = {key2data, sizeof(U_INT4)*3};       // DB ù????ù??ù??ù??ù??ù??ù??ù??
    DBT val = dbt_initializer;                                      // DB ù????ù??ù??ù??ù??ù??ù??ù??

    S_INT4 ret = dbp->get(dbp, NULL, &key, &val, 0);
    if (ret == 0) return(DBT2DECIM8(val));
    if (ret < 0)  return(0);
    perror("Case = -1");
    exit(-1);
#endif
}


//------------------------------------------------------------------------------------
//                       logP
//------------------------------------------------------------------------------------

// ù??ù??  ?? : ù??ù??ù????ù??ù??ù??ù??ù??ù????ù????ù??ù??ù??ù??ù????ù??ù????ù??ù????ù??ù??ù??

inline DECIM8 Markov::logP(U_INT4 suf1, U_INT4 suf2) const
{
#ifdef Markov_DEBUG
    cerr << "Markov::logP(U_INT4, U_INT4)" << endl;
#endif

    return(-log(prob(suf1, suf2)));
}


//------------------------------------------------------------------------------------
//                       prob
//------------------------------------------------------------------------------------

// ù??ù??  ?? : ù??ù??ù????ù??ù??ù??ù??ù??ù????ù????ù??ù??ù????ù??ù??ù??

inline DECIM8 Markov::prob(U_INT4 suf1, U_INT4 suf2) const
{
#ifdef Markov_DEBUG
    cerr << "Markov::prob(U_INT4, U_INT4)" << endl;
#endif

    return(L1*_1prob(suf2)+L2*_2prob(suf1, suf2));
}


//------------------------------------------------------------------------------------
//                       _1prob
//------------------------------------------------------------------------------------

// ù??ù??  ?? : 0 ù??????ù??ù????ù??ù????ù??ù????ù??ù??ù??ù??ù??ù????ù????ù??ù??ù????ù??ù??ù??

inline DECIM8 Markov::_1prob(U_INT4 suf2) const
{
#ifdef Markov_DEBUG
    cerr << "Markov::_1prob(U_INT4)" << endl;
#endif

    return((DECIM8)_1gram(suf2)/(DECIM8)_0gram());
}


//------------------------------------------------------------------------------------
//                       _2prob
//------------------------------------------------------------------------------------

// ù??ù??  ?? : 1 ù??????ù??ù????ù??ù????ù??ù????ù??ù??ù??ù??ù??ù????ù????ù??ù??ù????ù??ù??ù??

inline DECIM8 Markov::_2prob(U_INT4 suf1, U_INT4 suf2) const
{
#ifdef Markov_DEBUG
    cerr << "Markov::_2prob(U_INT4, U_INT4)" << endl;
#endif

    return((DECIM8)_2gram(suf1, suf2)/(DECIM8)_1gram(suf1));
}


//------------------------------------------------------------------------------------
//                       DBT2DECIM8
//------------------------------------------------------------------------------------

inline DECIM8 Markov::DBT2DECIM8(const DBT& val) const
{
#ifdef Markov_DEBUG
    cerr << "Markov::DBT2DECIM8(const DBT&)" << endl;
#endif

    DECIM8 temp = 0;
    for (U_INT4 i = 0; i < val.size; i++){
        if (((S_CHAR_P)val.data)[i] == '.'){      // ù??ù??ù??ù??ù??ù??
            DECIM8 shou = 0;                      // ù??ù??ù??ù??ù??ù??
            for (U_INT4 j = val.size-1; j > i; j--){
                shou += (DECIM8)(((U_INT1_P)val.data)[j]-'0');
                shou *= 0.1;
            }
            return(temp+shou);
        }
//        cerr << ((U_INT1_P)val.data)[i] << " ";
        temp *= 10;
        temp += (DECIM8)(((U_INT1_P)val.data)[i]-'0');
    }
//    cerr << endl;
//    exit(0);
    return(temp);
}


//------------------------------------------------------------------------------------
//                       test
//------------------------------------------------------------------------------------

void Markov::test(IntStr intstr, U_INT4 suf1, U_INT4 suf2) const
{
    cerr << "Freq(" << intstr[suf1] << " " << intstr[suf2] << ") = "
         << _2gram(suf1, suf2) << endl;
    cerr << "Freq(" << intstr[suf1] << ") = " << _1gram(suf1) << endl;
    cerr << "Freq(" << intstr[suf2] << ") = " << _1gram(suf2) << endl;
    cerr << "Freq() = " << _0gram() << endl;
}


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
