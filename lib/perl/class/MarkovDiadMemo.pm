#=====================================================================================
#                        MarkovDiadMemo.pm
#                             by Shinsuke MORI
#                             Last change : 26 June 2000
#=====================================================================================

# ��  ǽ : ñ���ޥ륳�ե��ǥ���ľ�ܥ��ɥ쥹ɽ(Direct Address Table)���Ѥ��Ƽ������롣
#
# ������ : �ʤ�


#-------------------------------------------------------------------------------------
#                        declalations
#-------------------------------------------------------------------------------------

require "class/Markov.pm";

package MarkovDiadMemo;
@ISA = qw( Markov );


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

$SUFFIX = ".diad";                                # �ե�����̾�γ�ĥ��


#-------------------------------------------------------------------------------------
#                        new
#-------------------------------------------------------------------------------------

# new(IntStr, SIZE)
# new(IntStr, SIZE, FILE)
#
# ��  ǽ : �ޥ륳�ե��ǥ��Τ�����ɽ���������롣

sub new{
    (@_ == 2) || (@_ == 3) || die;
    my($type, $size, $FILE) = @_;
    my($self) = {};

    $$self{"size"} = $size;
    $$self{"0-gram"} = 0;
    $$self{"1-gram"} = pack("I", 0) x $size;
    $$self{"2-gram"} = pack("I", 0) x ($size*$size);

#    my($HASH) = $FILE . ".db";                    # ��������������!!
#    tie(%hash, DB_File, $HASH, 0) || die "Can't open $HASH: $!\n";
#    $hash{"_size_"} = $$self{"size"};
#    untie(%hash);

    bless($self);

    $self->get($FILE) if (defined($FILE));

    return($self);
}


#-------------------------------------------------------------------------------------
#                        inc
#-------------------------------------------------------------------------------------

# inc(STATE, STATE);
#
# ��  ǽ : <STATE, STATE> �����٤򥤥󥯥������Ȥ��롣

sub inc{
    (@_ == 3) || die;
    my($self, $state1, $state2) = @_;

    $$self{"0-gram"}++;

    substr($$self{"1-gram"}, $state1*4, 4) =
        pack("I", unpack("I", substr($$self{"1-gram"}, $state1*4, 4))+1);

    substr($$self{"2-gram"}, ($state1*$self->{"size"}+$state2)*4, 4) =
        pack("I", unpack("I", substr($$self{"2-gram"}, ($state1*$self->size+$state2)*4, 4))+1);

    return($self);
}


#-------------------------------------------------------------------------------------
#                        add
#-------------------------------------------------------------------------------------

# add(Int, STATE, STATE);
#
# ��  ǽ : <STATE, STATE> �����٤� Int ���ä��롣

sub add{
    (@_ == 4) || die;
    my($self, $val, $state1, $state2) = @_;

    $$self{"0-gram"} += $val;

    substr($$self{"1-gram"}, $state1*4, 4) =
        pack("I", unpack("I", substr($$self{"1-gram"}, $state1*4, 4))+$val);

    substr($$self{"2-gram"}, ($state1*$self->{"size"}+$state2)*4, 4) =
        pack("I", unpack("I", substr($$self{"2-gram"}, ($state1*$self->size+$state2)*4, 4))+$val);

    return($self);
}


#-------------------------------------------------------------------------------------
#                        size
#-------------------------------------------------------------------------------------

# size;
#
# ��  ǽ : size ���֤���

sub size{
    (@_ == 1) || die;
    my($self) = @_;

    return($$self{"size"});
}


#-------------------------------------------------------------------------------------
#                        _0gram
#-------------------------------------------------------------------------------------

# _0gram
#
# ��  ǽ : 0-gram ������

sub _0gram{
    (@_ == 1) || die;
    my($self) = @_;

    return($$self{"0-gram"});
}


#-------------------------------------------------------------------------------------
#                        _1gram
#-------------------------------------------------------------------------------------

# _1gram(Number)
#
# ��  ǽ : 1-gram ������
#          Number : ���֤��ֹ�

sub _1gram{
    (@_ == 2) || die;
    my($self, $state1) = @_;

    return(unpack("I", substr($$self{"1-gram"}, $state1*4, 4)));
}


#-------------------------------------------------------------------------------------
#                        _2gram
#-------------------------------------------------------------------------------------

# _2gram(Number, Number)
#
# ��  ǽ : 2-gram ������
#          Number : ���֤��ֹ�

sub _2gram{
    (@_ == 3) || die;
    my($self, $state1, $state2) = @_;

    return(unpack("I", substr($$self{"2-gram"}, ($state1*$self->size+$state2)*4, 4)));
}


#-------------------------------------------------------------------------------------
#                        put
#-------------------------------------------------------------------------------------

# put(FILENAME);
#
# ��  ǽ : �ե������˽��Ϥ��롣

sub put{
    (@_ == 2) || die;
    my($self, $FILE) = @_;

    my($DIAD) = $FILE . $SUFFIX;
    (-e $DIAD) && unlink($DIAD);
    open(FILE, "> $DIAD") || die "Can't open $DIAD: $!\n";
    print FILE pack("I", $$self{"size"});
    print FILE pack("I", $$self{"0-gram"});
    printf(STDERR "size = %4d, 0-gram = %8d\n", $$self{"size"}, $$self{"0-gram"});
    print FILE $$self{"1-gram"};
    print FILE $$self{"2-gram"};
    close(FILE);

    return($self);
}


#-------------------------------------------------------------------------------------
#                        get
#-------------------------------------------------------------------------------------

# get(FILENAME);
#
# ��  ǽ : �ե����뤫�����Ϥ���

sub get{
    (@_ == 2) || die;
    my($self, $FILE) = @_;

    my($HASH) = $FILE . ".db";                    # ��������������!!
    if (-r $HASH){
        tie(%hash, DB_File, $HASH, 0) || die "Can't open $HASH: $!\n";
        while (($key, $val) = each(%hash)){
            if (length($key) == 4){
                $$self{"0-gram"} = $val;
            }elsif (length($key) == 8){
                $state1 = (unpack("II", $key))[0];
                substr($$self{"1-gram"}, $state1*4, 4) = pack("I", $val);
            }elsif (length($key) == 12){
                ($state1, $state2) = (unpack("III", $key))[0, 1];
#                printf(STDERR "(state1, state2) = (%d, %d)\n", $state1, $state2);
                substr($$self{"2-gram"}, ($state1*$$self{"size"}+$state2)*4, 4) =
                    pack("I", $val);
            }elsif ($key eq "_size_"){
                ;                                 # NOP
            }else{
                die;                              # ��ã���ʤ��Ϥ�
            }
        }
        untie(%hash);
        return($self);
    }

    my($DIAD) = $FILE . $SUFFIX;
    if (-r $DIAD){
        open(FILE, $DIAD) || die "Can't open $DIAD: $!\n";
        sysread(FILE, $_, 4);
        $$self{"0-gram"} = unpack("I", $_);
        sysread(FILE, $$self{"1-gram"}, 4*$self->size);
        sysread(FILE, $$self{"2-gram"}, 4*$self->size*$self->size);
        close(FILE);
        return($self);
    }

    die;
}


#-------------------------------------------------------------------------------------
#                        return
#-------------------------------------------------------------------------------------

1;


#=====================================================================================
#                        END
#=====================================================================================
