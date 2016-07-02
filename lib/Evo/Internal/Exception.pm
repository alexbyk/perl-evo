package Evo::Internal::Exception;
use Evo;

sub import($class) {
  my $caller = caller;
  no strict 'refs';    ## no critic
  *{"${caller}::exception"} = \&exception;
}

sub exception($sub) : prototype(&) {
  local $@;
  eval { $sub->() };
  $@;
}

1;
