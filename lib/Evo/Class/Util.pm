package Evo::Class::Util;
use Evo;
use Evo::Export '*';
use Carp 'croak';

sub croak_bad_value ($value, $name, $msg = undef) : Export {
  my $err = qq'Bad value "$value" for attribute "$name"';
  $err .= ": $msg" if $msg;
  croak $err;
}

1;
