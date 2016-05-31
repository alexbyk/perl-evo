package Evo::Loop::Role::Zone;
use Evo -Class::Role, '-Lib *; Carp croak carp';

has zone_data => sub { {middleware => [[]]} };

# calls callback with passed ws, and combines prev + passed for wcb
sub zone : Public {
  my ($self, $fn) = (shift, pop);
  my $data = $self->zone_data;
  local $data->{middleware} = [(map { [$_->@*] } $data->{middleware}->@*), []];
  $fn->();
}

# IDEA:
# Maybe register callback and return as is if already registered to prevent neighboard twice zone_cb
# return $cb if($STORE{$cb});
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

    # this is needed if someone will call zone_cb in blocking flow twice
    # for example, when using with other loop
    if ($data->{middleware_done}) {
      carp "zone_cb was called more than once; Ignoring superfluous";
      return $cb->();
    }
    local $data->{middleware_done} = 1;
    local $data->{cb_called}       = 1;
    local $data->{middleware}      = \@ws;
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
