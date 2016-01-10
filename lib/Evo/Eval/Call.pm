package Evo::Eval::Call;
use Evo;
use Carp 'croak';

sub result {
  return unless defined $_[0]->{wanted};
  $_[0]->{wanted} ? $_[0]->{result}->@* : $_[0]->{result}[0];
}

1;
