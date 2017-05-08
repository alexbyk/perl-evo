package Evo::Test::Item;
use Evo -Class;

has $_ for qw(fn filename index);
has status => 'waiting';
has error  => '';

our $CURRENT;
sub CURRENT($me) { $CURRENT || die "Not in DSL"; }

sub dsl_call ($self, $fn) {
  local $CURRENT = $self;
  $fn->();
}

sub invoke ($self, $continue) {
  $self->dsl_call(sub { $self->fn->($continue); });
}

1;
