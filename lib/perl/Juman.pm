use bytes;
package Juman;
require 5.000;
require Exporter;
use IPC::Open2;


# 指定された文を juman によって処理した結果を返す関数 juman を
# 定義したモジュール

@ISA = qw(Exporter);
@EXPORT = qw(juman);


# juman を起動する
&open2(JUMAN_OUT,JUMAN_IN,"/home/nagao/juman/bin/juman -e");


# juman の解析結果を返す関数
sub juman ($) {
    local( @lines );
    $_[0]=~s/\s+$//;		# 文末の改行文字などを取り除いておく
    print JUMAN_IN "$_[0]\n";
    while( $_=<JUMAN_OUT> ){
	last if /EOS/;
	chop;
	push( @lines,$_ );
    }
    @lines;
}


1;
