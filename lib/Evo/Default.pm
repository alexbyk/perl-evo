package Evo::Default;
use strict;
use warnings;

sub import {
  $_->import for qw(strict warnings utf8);
  feature::->import(':5.22');

  feature::->import('postderef');
  warnings::->unimport('experimental::postderef');

  feature::->import('signatures');
  warnings::->unimport('experimental::signatures');

  feature::->import('lexical_subs');
  warnings::->unimport('experimental::lexical_subs');
}

1;

=head1 SYNOPSYS

  # strict, warnings, utf8, :5.20, postderef
  use Evo;

=head1 DESCRIPTION

Enables default features and disable warnings for them

=cut
