package Evo::Promises::Util;
use Evo '-Export *';
use List::Util 'first';
use Carp 'croak';

use constant {PENDING => 'PENDING', REJECTED => 'REJECTED', FULFILLED => 'FULFILLED'};

export qw(PENDING REJECTED FULFILLED);

sub is_locked_in($parent, $child) : Export {
  croak unless defined wantarray;
  first { $_ == $child } $parent->d_children->@*;
}

sub is_fulfilled_with($v, $p) : Export {
  croak unless defined wantarray;
  return unless $p->d_settled && $p->{state} eq FULFILLED;
  my $dv = $p->d_v;
  return defined $dv ? $v eq $dv : !defined $dv;
}

sub is_rejected_with($v, $p) : Export {
  croak unless defined wantarray;
  return unless $p->d_settled && $p->{state} eq REJECTED;
  my $dv = $p->d_v;
  return defined $dv ? $v eq $dv : !defined $dv;
}


1;
