package Evo::Loop::Role::Zone;
use Evo -Class::Role, '-Lib *; Carp croak';

has zone_data => sub { {middleware => []} };

# calls callback with passed ws, and combines prev + passed for wcb
sub zone : Public {
  my ($self, $fn) = (shift, pop);
  my $data = $self->zone_data;
  local $data->{middleware} = [$data->{middleware}->@*];
  $fn->();
}

sub zone_cb ($self, $cb) : Public {
  my $data = $self->zone_data;
  my @ws   = $data->{middleware}->@*;

  sub {
    local $data->{middleware} = \@ws;
    ws_fn(@ws, $cb)->();
  };
}

sub zone_middleware ($self, @mw) : Public {
  my $mw = $self->zone_data->{middleware};
  push $mw->@*, @mw if @mw;
  $mw;
}


1;
