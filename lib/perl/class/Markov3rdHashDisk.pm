#=====================================================================================
#                        Markov3rdHashDisk.pm
#                             by Shinsuke MORI
#                             Last change : 25 March 1997
#=====================================================================================

# ��  ǽ : ñ��ޥ륳�ե�ǥ��ϥå�����Ѥ��Ƽ������롣
#
# ������ : �����󤫤�ϥå��奭���ؤδؿ���Ϣ�ܤǤ��ꡢ���줬ñ�ͤȤʤ�ɬ�פ����롣


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

require "class/Markov3rdHash.pm";

package MarkovHashDisk;
@ISA = qw( MarkovHash );

use Carp;
use POSIX;
use DB_File;


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

$SUFFIX = ".db";                                # �ե�����̾�γ�ĥ��


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new(IntStr, SIZE, FILE)
#
# ��  ǽ : �ޥ륳�ե�ǥ�Τ���Υϥå�����������롣

sub new{
    (@_ == 3) || die;
    my($type, $size, $FILE) = @_;
    printf(STDERR "%s::new(%d, %s)\n", $type, $size, $FILE);

    my(%hash);
    my($HASH) = $FILE . $SUFFIX;
    if (-e $HASH){
        tie(%hash, DB_File, $HASH, O_RDWR) || die "Can't open $HASH: $!\n";
    }else{
        tie(%hash, DB_File, $HASH, O_CREAT|O_RDWR) || die "Can't open $HASH: $!\n";
        $hash{"_size_"} = $size;
    }

    return(bless(\%hash));
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================