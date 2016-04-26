#!/usr/bin/env perl
use bytes;
#=====================================================================================
#                        split.perl<2>
#                             by Shinsuke MORI
#                             Last change : 18 November 2001
#=====================================================================================

# 機  能 : ファイルを読み込み、ソートしてユニークする。
#
# 使用法 : sortuniq.perl
#
# 実  例 : sortuniq.perl
#
# 注意点 : なし


#-------------------------------------------------------------------------------------
#                        require
#-------------------------------------------------------------------------------------

use Env;
use POSIX;
use English;
use File::Basename;
unshift(@INC, dirname($0), "$HOME/usr/lib/perl", "$HOME/CrossEntropy/methods");

require "Help.pm";
require "Mathematics.pm";


#-------------------------------------------------------------------------------------
#                        check arguments
#-------------------------------------------------------------------------------------

#((@ARGV == 1) && ($ARGV[0] ne "-help")) || &Help($0);
#print STDERR join(" ", basename($0), @ARGV), "\n";

$STEP = 4;


#-------------------------------------------------------------------------------------
#                        set variables
#-------------------------------------------------------------------------------------

$INPUT_RECORD_SEPARATOR = "\n\n";

$FileNo = 1;
$FILE = sprintf("EHJ%04d.cps", $FileNo);
open(FILE, "| /usr/bin/nkf -s > $FILE") || die "Can't open $FILE: $!\n";
for ($SentNo = 1; <>; $SentNo++){
    print FILE $_;
    if ($SentNo%100 == 0){
        close(FILE);
        $FileNo++;
        $FILE = sprintf("EHJ%04d.cps", $FileNo);
        open(FILE, "| /usr/bin/nkf -s > $FILE") || die "Can't open $FILE: $!\n";
    }
}
close(FILE);
exit(0);

$Y = join("|", map(sprintf("%d", $_), 1990 .. 2001));
$M = join("|", map(sprintf("%d", $_), 1 .. 12));
$D = join("|", map(sprintf("%d", $_), 1 .. 31));

while (<>){
    (m|($Y)年($M)月($D)日</td><td>([\d,]+)</td><td>([\d,]+)</td><td>([\d,]+)</td><td><b>([\d,]+)</b></td><td>([\d,]+)</td><td>([\d,]+)</td>|) || next;
    printf("%04d/%02d/%02d %6s %6s %6s %6s %9s\n", $1, $2, $3, $4, $5, $6, $7, $8);
}

#$FILE = "type.text";
#open(FILE) || die "Can't open $FILE: $!\n";
#%TYPE = map((split)[0, 2], <FILE>);
#close(FILE);

#printf("%s => %s\n", $key, $val) while (($key, $val) = each(%TYPE));


#-------------------------------------------------------------------------------------
#                        main
#-------------------------------------------------------------------------------------

# 機  能 : 「形態素-形態素 => type」 のファイルを作成する


$INPUT_RECORD_SEPARATOR = "\n\n";

%HASH = ();
while (<>){
    ($head, @elem) = split("\n");
    pop(@elem);
    @part = @morp = @dest = @type = ();
    for ($i = 0; $i < $#elem; $i++){
#        warn $elem[$i], "\n";
        ($word, @rest) = split(" ", $elem[$i]);
        push(@part, (split("=", $rest[0]))[1]);
        push(@morp, sprintf("%s/%s", $word, $part[$i]));
        push(@dest, (split("=", $rest[1]))[1]-1);
        push(@type, substr((split("=", $rest[2]))[1], 0, 3));
    }
    (($#elem == @part) && ($#elem == @morp) && ($#elem == @dest) && ($#elem == @type))
        || die;
    ($word, @rest) = split(" ", $elem[$i]);
    push(@part, (split("=", $rest[0]))[1]);
    push(@morp, sprintf("%s/%s", $word, $part[$i]));

    for ($i = 0; $i < $#elem; $i++){
        $HASH{sprintf("%s-%s %s", $morp[$i], $morp[$dest[$i]], $type[$i])}++;
#        printf("%s => %s\n", join(" ", ($morp[$i], $morp[$dest[$i]])), $type[$i]);
        $HASH{sprintf("%s-%s %s", $part[$i], $part[$dest[$i]], $type[$i])}++;
#        printf("%s => %s\n", join(" ", ($morp[$i], $morp[$dest[$i]])), $type[$i]);
    }
}

%TYPE = %FREQ = ();
while (($key, $val) = each(%HASH)){               # 最大頻度のタイプの選択
#    printf("%6d %s => %s\n", $val, split(" ", $key));
    ($comb, $type) = split(" ", $key);
    if ($val > $FREQ{$comb}){
        $TYPE{$comb} = $type;
        $FREQ{$comb} = $val;
    }
}

while (($key, $val) = each(%TYPE)){
    printf("%s => %s\n", $key, $val);
}


#-------------------------------------------------------------------------------------
#                        close
#-------------------------------------------------------------------------------------

exit(0);


#=====================================================================================
#                        END
#=====================================================================================
