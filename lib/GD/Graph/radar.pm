#==============================================
#    Copyright (c) 2003 Brad Murray
#----------------------------------------------
#
#    Name: GD::Graph::radar.pm
#
#==============================================

package GD::Graph::radar;

$GD::Graph::pie::VERSION = '0.02';

use strict;

use constant PI => 4 * atan2(1, 1);

use GD;
use GD::Graph;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours :lists);
use GD::Text::Align;
use Carp;

@GD::Graph::radar::ISA = qw(GD::Graph);

my $ANGLE_OFFSET = 90;

my %Defaults = (
    # The angle at which to start the first data set
    # 0 is pointing straight down
    start_angle => 0,

    # and some public attributes without defaults
    label => undef,

    # Absolute graphs always start at zero and cannot have negative
    # values.  non-absolute graphs start at minimum data set value
    absolute => 1,

    # number of scale markers to draw
    nmarkers => 6,

    # if set, draw a polygon connecting the apices of each line
    polygon => 1,

    # if defined, fill the polygon with the colour specified as
    # a hex rgb string.  Note that if one of the data
    # elements is zero, then the polygon will not fill as we fill
    # from the origin
    poly_fill => '#e4e4e4',
);

# PRIVATE
sub _has_default { 
    my $self = shift;
    my $attr = shift || return;
    exists $Defaults{$attr} || $self->SUPER::_has_default($attr);
}

sub initialise {
    my $self = shift;
    $self->SUPER::initialise();
    while (my ($key, $val) = each %Defaults) {
        $self->{$key} = $val;
    }
    $self->set_value_font(gdTinyFont);
    $self->set_label_font(gdSmallFont);
}

# PUBLIC methods, documented in pod
sub plot {
    my $self = shift;
    my $data = shift;

    $self->check_data($data) or return;
    $self->init_graph()      or return;
    $self->setup_text()      or return;
    $self->setup_coords()    or return;
    $self->draw_text()       or return;
    $self->draw_data()       or return;

    return $self->{graph};
}

sub set_label_font {  # (fontname)
    my $self = shift;
    $self->_set_font('gdta_label', @_) or return;
    $self->{gdta_label}->set_align('bottom', 'center');
}

sub set_value_font {  # (fontname)
    my $self = shift;
    $self->_set_font('gdta_value', @_) or return;
    $self->{gdta_value}->set_align('center', 'center');
}

# Inherit defaults() from GD::Graph

# inherit checkdata from GD::Graph

# Setup the coordinate system and colours, calculate the
# relative axis coordinates in respect to the canvas size.

sub setup_coords() {
    my $self = shift;

    # Make sure we're not reserving space we don't need.

    my $tfh = $self->{title} ? $self->{gdta_title}->get('height') : 0;
    my $lfh = $self->{label} ? $self->{gdta_label}->get('height') : 0;

    # Calculate the bounding box for the graph, and
    # some width, height, and centre parameters
    $self->{bottom} = 
        $self->{height} - $self->{b_margin} -
        ( $lfh ? $lfh + $self->{text_space} : 0 );
    $self->{top} = 
        $self->{t_margin} + ( $tfh ? $tfh + $self->{text_space} : 0 );

    return $self->_set_error('Vertical size too small') 
        if $self->{bottom} - $self->{top} <= 0;

    $self->{left}  = $self->{l_margin};
    $self->{right} = $self->{width} - $self->{r_margin};

    return $self->_set_error('Horizontal size too small')
        if $self->{right} - $self->{left} <= 0;

    $self->{w} = $self->{right}  - $self->{left};
    $self->{h} = $self->{bottom} - $self->{top};

    $self->{xc} = ($self->{right}  + $self->{left}) / 2;
    $self->{yc} = ($self->{bottom} + $self->{top})  / 2;

    return $self;
}

# inherit open_graph from GD::Graph

# Setup the parameters for the text elements
sub setup_text {
    my $self = shift;

    if ($self->{title}) {
        #print "'$s->{title}' at ($s->{xc},$s->{t_margin})\n";
        $self->{gdta_title}->set(colour => $self->{tci});
        $self->{gdta_title}->set_text($self->{title});
    }

    if ($self->{label}) {
        $self->{gdta_label}->set(colour => $self->{lci});
        $self->{gdta_label}->set_text($self->{label});
    }

    $self->{gdta_value}->set(colour => $self->{alci});

    return $self;
}

# Put the text on the canvas.
sub draw_text {
    my $self = shift;

    $self->{gdta_title}->draw($self->{xc}, $self->{t_margin}) 
        if $self->{title}; 
    $self->{gdta_label}->draw($self->{xc}, $self->{height} - $self->{b_margin})
        if $self->{label};
    
    return $self;
}

# Draw the data lines and the polygon

sub draw_data {
    my $self = shift;

    my $max_val = 0;
    my @values = $self->{_data}->y_values(1);   # for now, only one
    my $min_val = $values[0];
        my $scale = 1;

    for (@values) {    
        if ($_ > $max_val) { $max_val = $_; }
        if ($_ < $min_val) { $min_val = $_; }
    }

    if ($self->{absolute}) {
        $scale = ($self->{w} / 2) / $max_val;
    }
    else {
        $scale = ($self->{w} / 2) / ($max_val - $min_val);
    }
       
    my $ac = $self->{acci};  # Accent colour
    my $pb = $self->{start_angle};

    my $poly = new GD::Polygon;
    my @vertices = ();

    for (my $i = 0; $i < @values; $i++) {
        # Set the angles of each arm
        # Angle 0 faces down, positive angles are clockwise 
        # from there.
        #   ---
        #  /   \
        # |     |
        #  \ | /
        #   ---
        #    0
        # $pa/$pb include the start_angle (so if start_angle
        # is 90, there will be no pa/pb < 90.
        my $pa = $pb;
        $pb += my $slice_angle = 360 / @values;

        # Calculate the end points of the lines at the boundaries of
        # the pie slice
        my $radius = $values[$i] * $scale;
        if ($radius < 0 && $self->{absolute}) {
            $radius = 0;
        }
        my ($xe, $ye) = cartesian(
            $radius,
            $pa, 
            $self->{xc}, $self->{yc},
            $self->{h} / $self->{w}
        );
        if ($self->{polygon}) {
            $poly->addPt($xe, $ye);
        }
        push(@vertices, [$xe, $ye]);

    }

    # draw the apex polygon
    $self->{graph}->polygon($poly, $ac);
    if (defined $self->{poly_fill}) {
        my ($r, $g, $b) = GD::Graph::colour::hex2rgb($self->{poly_fill});
        my $fc = $self->{graph}->colorAllocate($r, $g, $b);
        $self->{graph}->fill($self->{xc}, $self->{yc}, $fc);
    }

        # draw markers
    my $mark_incr = 1;
    if ($self->{absolute}) {
        $mark_incr = int ($max_val / $self->{nmarkers});
    }
    else {
        $mark_incr = int (($max_val - $min_val) / $self->{nmarkers});
    }
    for (1 .. $self->{nmarkers}) {
        my $width = 2 * $_ * $mark_incr * $scale;
        $self->{graph}->arc(
            $self->{xc}, $self->{yc},
            $width,
            $width * ($self->{h} / $self->{w}), 
            0, 360,
            $ac,
        );
    }

    # draw radar value bars
    my $dc = $self->{graph}->colorAllocate(0, 0, 0);
    for (@vertices) {
        $self->{graph}->line(
            $self->{xc}, $self->{yc},
            $_->[0], $_->[1],
            $dc
        );
    }

    # draw labels
    $pb = $self->{start_angle};
    for (my $i = 0; $i < @values; $i++) {
        next unless $values[$i];

        my $pa = $pb;
        $pb += my $slice_angle = 360 / @values;

        next if $self->{suppress_angle} && $slice_angle <= $self->{suppress_angle};

        my ($xe, $ye) = cartesian(
              3 * $self->{w} / 8, $pa,
              $self->{xc}, $self->{yc},
              $self->{h} / $self->{w}
        );

        $self->put_slice_label($xe, $ye, $self->{_data}->get_x($i));
    }
       
    return $self;

}  #GD::Graph::radar::draw_data

# put the slice label on the pie
sub put_slice_label {
    my $self = shift;
    my ($x, $y, $label) = @_;

    return unless defined $label;

    $self->{gdta_value}->set_text($label);
    $self->{gdta_value}->draw($x, $y);
}

# return x, y coordinates from input
# radius, angle, center x and y and a scaling factor (height/width)
#
# $ANGLE_OFFSET is used to define where 0 is meant to be
sub cartesian {
    my ($r, $phi, $xi, $yi, $cr) = @_; 

    return (
        $xi + $r * cos(PI * ($phi + $ANGLE_OFFSET) / 180),
        $yi + $cr * $r * sin(PI * ($phi + $ANGLE_OFFSET) / 180)
    )
}

1;

__END__

=head1 NAME

GD::Graph::radar - Make radial bar charts

=head1 SYNOPSIS

  use GD::Graph::radar;
  my $radar = GD::Graph::radar->new(400, 400);
  my $image = $radar->plot([
      [ qw( a    b  c    d    e    f    g  h    i )],
      [     3.2, 9, 4.4, 3.9, 4.1, 4.3, 7, 6.1, 5  ]
  ]);

  binmode STDOUT;
  $filename = "$0.png";
  open PNG, ">$filename" or die "Can't open $filename - $!\n";
  binmode PNG;
  print PNG $image->png;
  close PNG;

=head1 DESCRIPTION

This module is based on C<GD::Graph::pie> with the exception of 
changes to the default settings, the C<draw_data> method, and 
elimination of the pie specific code.

=head1 ABSTRACT

Make radial bar charts

=head1 SEE ALSO

L<GD::Graph>

L<GD::Graph::pie>

C<http://www.phreeow.net/radar/>

=head1 AUTHOR

Brad J. Murray E<lt>bjm@phreeow.netE<gt>

CPAN distribution by Gene Boggs E<lt>gene@cpan.orgE<gt>

GD::Graph by Martien Verbruggen E<lt>mgjv@tradingpost.com.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Brad J. Murray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
