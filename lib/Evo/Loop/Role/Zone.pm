package Evo::Loop::Role::Zone;
use Evo '-Class *, -new', '-Lib *; Carp carp croak';

has zone_data => sub { {middleware => [[]]} };

# calls callback with passed ws, and combines prev + passed for wcb
sub zone {
  my ($self, $fn) = (shift, pop);
  my $data = $self->zone_data;
  local $data->{middleware} = [(map { [$_->@*] } $data->{middleware}->@*), []];
  $fn->();
}

# IDEA:
# Maybe register callback and return as is if already registered to prevent neighboard twice zone_cb
# return $cb if($STORE{$cb});
sub zone_cb ($self, $cb) {
  my $data = $self->zone_data;

  # special case no middleware, optimization
  #if ($data->{middleware}->@* == 1 && !$data->{middleware}[0]->@*) {
  #  return sub {
  #    local $data->{middleware} = [[]];
  #    $cb->(@_);
  #  };
  #}

  my @ws = map { [$_->@*] } $data->{middleware}->@*;

  sub {
    # this is needed if someone will call zone_cb in blocking flow twice
    # for example, when using with other loop
    if ($data->{middleware_done}) {
      carp "zone_cb was called more than once; Ignoring superfluous";
      return $cb->(@_);
    }
    local $data->{middleware_done} = 1;
    local $data->{cb_called}       = 1;
    local $data->{middleware}      = \@ws;
    ws_fn((map { $_->@* } @ws), $cb)->(@_);
  };
}

sub zone_middleware ($self, @mw) {
  my $mw = $self->zone_data->{middleware};
  push $mw->[-1]->@*, @mw if @mw;
  map { $_->@* } $mw->@*;
}

sub zone_level($self) { return $self->zone_data->{middleware}->$#*; }

sub zone_goto ($self, $level) {
  croak "Bad level $level (max ${\$self->zone_level})" unless $level < $self->zone_level;
  my $data = $self->zone_data;
  $data->{middleware} = [map { [$_->@*] } @{$data->{middleware}}[0 .. $level]];
}

1;
