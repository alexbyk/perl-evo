package Evo::Test::Call;
use Evo -Class;

has 'args';
has 'exception', optional;
has 'result_fn';

sub result($self) {
  return unless $self->result_fn;
  $self->result_fn->();
}

1;
