use strict;
use Test::More tests => 6;

BEGIN { use_ok 'GD::Graph::radar' };

my $g;
eval {
    $g = GD::Graph::radar->new(400, 400);
};
isa_ok $g, 'GD::Graph::radar';
ok !$@, 'object created';

my $i;
eval {
    $i = $g->plot([
        [qw(a    b  c    d    e    f    g  h    i)],
        [   3.2, 9, 4.4, 3.9, 4.1, 4.3, 7, 6.1, 5 ]
    ]);
};
ok !$@, 'image plotted';

# MrDath++ (A.K.A. DrMath++, A.K.A. KWILLIAMS++)
my $format  = GD::Image->can('gif') && GD::Image->new(1, 1)->gif
    ? 'gif' : 'png';
my $outfile = "t/1.$format";

eval {
    open F, ">$outfile" or die "Can't open $outfile - $!\n";
    binmode F;
    print F $i->$format();
    close F;
};
ok !$@, "image file written as $outfile";
ok -e $outfile, 'image file exists';

# I cannot get an account on a Solaris box to fix this test.  Anyway,
# I suspect that the problem is endian-ness...
SKIP: {
    skip 'Ack! Solaris! Run!', 1 if $^O eq 'solaris';

    ok files_identical($outfile, "t/test.$format"), 'files are identical';

    # This sub lifted from KWILLIAMS' Image::Timeline test suite.
    sub files_identical {
        my ($one, $two) = @_;
        local $/;
        my $data_one = do { local *F; open F, $one or die "$one: $!"; binmode F; <F>; };
        my $data_two = do { local *F; open F, $two or die "$two: $!"; binmode F; <F>; };
        return $data_one eq $data_two;
    }
}
