package Evo::Class::Syntax;
use Evo '-Export *; Carp croak; Scalar::Util reftype';

use constant SYNTAX_STATE => {};

export qw(SYNTAX_STATE);

my sub _check_settled($key) {
  croak qq#syntax error: "$key" already settled# if SYNTAX_STATE()->{$key};
}

sub inject($dep) : prototype($) : Export {
  _check_settled('inject');
  SYNTAX_STATE->{inject} = $dep;
  SYNTAX_STATE;
}

sub check($fn) : prototype($) : Export {
  _check_settled('check');
  SYNTAX_STATE->{check} = $fn;
  SYNTAX_STATE;
}

sub lazy : prototype() : Export {
  _check_settled('lazy');
  SYNTAX_STATE->{lazy}++;
  SYNTAX_STATE;
}

sub rw() : prototype() : Export {
  _check_settled('rw');
  SYNTAX_STATE()->{rw}++;
  SYNTAX_STATE;
}

sub optional() : prototype() : Export {
  _check_settled('optional');
  SYNTAX_STATE->{optional}++;
  SYNTAX_STATE;
}

sub syntax_reset() : prototype() : Export {
  my %state = SYNTAX_STATE->%*;
  SYNTAX_STATE->%* = ();
  %state;
}

1;
