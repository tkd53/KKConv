# KKConv: かな漢字変換システムと辞書生成ツール

Copyright (C): Shinsuke Mori

For the licence, see LICENSE.txt

## セットアップ

corpusを入手してリポジトリ直下のcorpusディレクトリに展開

C++のBerkley dbとperlのBerkley dbでバージョンを揃えること。plenvが便利。

## ビルド
```
make all
```

## 使い方
```
./src/main
```
何かを入力。文字コードはEUC

## クリーンアップ
```
make allclean
```
