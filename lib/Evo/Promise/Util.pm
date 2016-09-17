package Evo::Promise::Util;
use Evo '-Export *; List::Util first; Carp croak; /::Const *';

sub is_locked_in ($parent, $child) : Export {
  croak unless defined wantarray;
  first { $_ == $child } $parent->d_children->@*;
}

sub is_fulfilled_with ($v, $p) : Export {
  croak unless defined wantarray;
  return unless $p->d_settled && $p->state eq FULFILLED;
  my $dv = $p->d_v;

  return defined $dv ? $v eq $dv : !defined $v;
}

sub is_rejected_with ($v, $p) : Export {
  croak unless defined wantarray;
  return unless $p->d_settled && $p->state eq REJECTED;
  my $dv = $p->d_v;
  return defined $dv ? $v eq $dv : !defined $v;
}


1;
