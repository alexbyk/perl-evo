package Evo::Promise::Util;
use Evo '-Export *';
use List::Util 'first';
use Carp 'croak';

use constant {PENDING => 'PENDING', REJECTED => 'REJECTED', FULFILLED => 'FULFILLED'};

export qw(PENDING REJECTED FULFILLED);

sub is_locked_in ($parent, $child) : Export {
  croak unless defined wantarray;
  first { $_ == $child } $parent->d_children->@*;
}

sub is_fulfilled_with ($v, $p) : Export {
  croak unless defined wantarray;
  return unless $p->d_settled && $p->{state} eq FULFILLED;
  my $dv = $p->d_v;

  return defined $dv ? $v eq $dv : !defined $v;
}

sub is_rejected_with ($v, $p) : Export {
  croak unless defined wantarray;
  return unless $p->d_settled && $p->{state} eq REJECTED;
  my $dv = $p->d_v;
  return defined $dv ? $v eq $dv : !defined $v;
}

sub promise_resolve($v) : Export {
  my $d = Evo::Promise::Deferred->new(promise => Evo::Promise::Class->new());
  $d->resolve($v);
  $d->promise;
}

sub promise_reject($v) : Export {
  my $d = Evo::Promise::Deferred->new(promise => Evo::Promise::Class->new());
  $d->reject($v);
  $d->promise;
}

sub promise_race : Export {
  my $d = Evo::Promise::Deferred->new(promise => Evo::Promise::Class->new());
  my $onF = sub { $d->resolve(@_) };
  my $onR = sub { $d->reject(@_) };
  foreach my $cur (@_) {
    if (ref $cur eq 'Evo::Promise::Class') {
      $cur->then($onF, $onR);
    }
    else {
      # wrap with our promise
      my $wd = Evo::Promise::Deferred->new(promise => Evo::Promise::Class->new());
      $wd->promise->then($onF, $onR);
      $wd->resolve($cur);
    }
  }

  $d->promise;
}

sub promise_all : Export {
  my $d = Evo::Promise::Deferred->new(promise => Evo::Promise::Class->new());
  do { $d->resolve([]); return $d->promise; } unless @_;

  my @prms    = @_;
  my $pending = @prms;

  my @result;
  my $onR = sub { $d->reject($_[0]) };

  for (my $i = 0; $i < @prms; $i++) {
    my $cur_i = $i;
    my $cur_p = $prms[$cur_i];
    my $onF   = sub { $result[$cur_i] = $_[0]; $d->resolve(\@result) if --$pending == 0; };

    if (ref $cur_p eq 'Evo::Promise::Class') {
      $cur_p->then($onF, $onR);
    }
    else {
      # wrap with our promise
      my $wd = Evo::Promise::Deferred->new(promise => Evo::Promise::Class->new());
      $wd->promise->then($onF, $onR);
      $wd->resolve($cur_p);
    }
  }
  $d->promise;
}


1;
