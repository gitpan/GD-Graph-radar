use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'GD::Graph::radar',
    'VERSION_FROM' => 'lib/GD/Graph/radar.pm',
    'PREREQ_PM'    => {
        'GD' => 0,
        'GD::Graph' => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/GD/Graph/radar.pm',
           AUTHOR        => 'Brad J. Murray <bjm@phreeow.net>')
        : ()),
);
