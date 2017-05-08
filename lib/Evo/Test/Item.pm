package Evo::Test::Item;
use Evo -Class;

has $_ for qw(fn filename index);
has status => 'waiting';
has error => '';

sub invoke ($self, $continue) {
  $self->fn->($continue);
}

1;
