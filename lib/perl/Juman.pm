use bytes;
package Juman;
require 5.000;
require Exporter;
use IPC::Open2;


# ���ꤵ�줿ʸ�� juman �ˤ�äƽ���������̤��֤��ؿ� juman ��
# ��������⥸�塼��

@ISA = qw(Exporter);
@EXPORT = qw(juman);


# juman ��ư����
&open2(JUMAN_OUT,JUMAN_IN,"/home/nagao/juman/bin/juman -e");


# juman �β��Ϸ�̤��֤��ؿ�
sub juman ($) {
    local( @lines );
    $_[0]=~s/\s+$//;		# ʸ���β���ʸ���ʤɤ�������Ƥ���
    print JUMAN_IN "$_[0]\n";
    while( $_=<JUMAN_OUT> ){
	last if /EOS/;
	chop;
	push( @lines,$_ );
    }
    @lines;
}


1;
