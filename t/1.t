use strict;
use Test::More 'no_plan';#tests => 1;

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

# MrDath++ (A.K.A. DrMath++ && KWILLIAMS++)
my $format  = GD::Image->new(1, 1)->gif ? 'gif' : 'png';
my $outfile = "t/1.$format";

eval {
    open F, ">$outfile" or die "Can't open $outfile - $!\n";
    binmode F;
    print F $i->$format;
    close F;
};
ok !$@, "image file written as $outfile";
ok -e $outfile, 'image file exists';

ok files_identical($outfile, "t/test.$format"), 'files are identical';

# This sub lifted, as is, from KWILLIAMS' Image::Timeline test suite.
sub files_identical {
  my ($one, $two) = @_;
  local $/;
  my $data_one = do {local *F; open F, $one or die "$one: $!"; <F>};
  my $data_two = do {local *F; open F, $two or die "$two: $!"; <F>};
  return $data_one eq $data_two;
}
