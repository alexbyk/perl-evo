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

  # special case no middleware, optimization
  #if ($data->{middleware}->@* == 1 && !$data->{middleware}[0]->@*) {
  #  return sub {
  #    local $data->{middleware} = [[]];
  #    $cb->();
  #  };
  #}

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

sub zone_level($self) : Public { return $self->zone_data->{middleware}->$#*; }

sub zone_escape ($self, $level, $fn) : Public {
  my $data = $self->zone_data;
  croak "Bad level $level (max ${\$self->zone_level})" unless $level < $self->zone_level;
  local $data->{middleware} = [map { [$_->@*] } @{$data->{middleware}}[0 .. $level]];
  $fn->();
}


1;
