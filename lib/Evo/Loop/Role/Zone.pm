package Evo::Loop::Role::Zone;
use Evo -Class::Role, '-Lib *; Carp croak';

has zone_data => sub { {middleware => [[]]} };

# calls callback with passed ws, and combines prev + passed for wcb
sub zone : Public {
  my ($self, $fn) = (shift, pop);
  my $data = $self->zone_data;
  local $data->{middleware} = [(map { [$_->@*] } $data->{middleware}->@*), []];
  $fn->();
}

sub zone_cb ($self, $cb) : Public {
  my $data = $self->zone_data;
  my @ws = map { [$_->@*] } $data->{middleware}->@*;

  sub {
    local $data->{middleware} = \@ws;
    ws_fn((map { $_->@* } @ws), $cb)->();
  };
}

sub zone_middleware ($self, @mw) : Public {
  my $mw = $self->zone_data->{middleware};
  push $mw->[-1]->@*, @mw if @mw;
  map { $_->@* } $mw->@*;
}

sub zone_level($self) : Public {
  return $self->zone_data->{middleware}->$#*;
}


1;
