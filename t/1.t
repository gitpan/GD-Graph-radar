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
        [ qw( a    b  c    d    e    f    g  h    i )],
        [     3.2, 9, 4.4, 3.9, 4.1, 4.3, 7, 6.1, 5  ]
    ]);
};
ok !$@, 'image plotted';
