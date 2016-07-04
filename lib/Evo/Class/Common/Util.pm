package Evo::Class::Common::Util;
use Evo 'Carp croak';

our @CARP_NOT = qw(Evo::Class::Gen);

sub croak_bad_value ($value, $name, $msg = undef) {
  my $err = qq'Bad value "$value" for attribute "$name"';
  $err .= ": $msg" if $msg;
  croak $err;
}

sub register_and_import ($me, @list) {
  my $caller = caller;
  Evo::Class::Meta->register($caller);
  my $gen = $me->class_of_gen->register($caller);
  Evo::Export->install_in($caller, $me, @list ? @list : '*');
}

1;
