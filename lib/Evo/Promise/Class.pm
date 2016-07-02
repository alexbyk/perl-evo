package Evo::Promise::Class;
use Evo -Class;
use Evo '-Loop loop_postpone';
use Evo '-Promise::Sync; -Promise::Util FULFILLED REJECTED PENDING promise_resolve promise_reject';
use Evo 'Carp croak;Scalar::Util blessed';

# https://promiseaplus.com/

has $_ for qw(d_v d_locked d_fh d_rh d_settled);
has 'd_children' => sub { [] };
has 'state' => PENDING;

#sub assert { shift or croak join '; ', caller() }

#sub value($self) {
#  croak "$self isn't fulfilled" unless $self->state eq FULFILLED;
#  $self->d_v;
#}
#
#sub reason($self) {
#  croak "$self isn't rejected" unless $self->state eq REJECTED;
#  $self->d_v;
#}


sub finally ($self, $fn) {
  my $d = Evo::Promise::Deferred->new(promise => ref($self)->new);
  my $onF = sub($v) {
    $d->resolve($fn->());    # need pass result because it can be a promise
    $d->promise->then(sub {$v});
  };
  my $onR = sub($r) {
    $d->resolve($fn->());    # see above
    $d->promise->then(sub { promise_reject($r) });
  };
  $self->then($onF, $onR);
}

sub catch ($self, $cfn) {
  $self->then(undef, $cfn);
}

sub spread ($self, $fn) {
  $self->then(sub($ref) { $fn->($ref->@*) });
}


sub then {
  my ($self, $fh, $rh) = @_;
  my $p = ref($self)->new(ref($fh) ? (d_fh => $fh) : (), ref($rh) ? (d_rh => $rh) : ());
  push $self->d_children->@*, $p;
  $self->d_traverse if $self->d_settled;
  $p;
}

sub d_lock_in ($self, $parent) {

  #assert(!$self->d_locked);
  #assert(!$self->d_settled);
  unshift $parent->d_children->@*, $self->d_locked(1);
}

sub d_fulfill ($self, $v) {

  #assert(!$self->d_settled);
  $self->d_settled(1)->state(FULFILLED)->d_v($v);
}

sub d_reject ($self, $r) {

  #assert(!$_[0]->d_settled);
  $self->d_settled(1)->state(REJECTED)->d_v($r);
}

# 2.3 The Promise Resolution Procedure
# 2.3.3.2, 2.3.3.4 doesn't make sense in perl (in real world)
# Changed term obj or func to blessed obj and can "then"
sub d_resolve ($self, $x) {

  #assert(!$self->d_settled);

  while (1) {

    # 2.3.4 but means not a blessed object
    return $self->d_fulfill($x) unless blessed($x);


    # 2.3.1
    return $self->d_reject('TypeError') if $x && $self eq $x;

    # 2.3.2 promise
    if (ref $x eq ref $self) {
      $x->d_settled
        ? $x->state eq FULFILLED
          ? $self->d_fulfill($x->d_v)
          : $self->d_reject($x->d_v)
        : $self->d_lock_in($x);
      return;
    }

    if ($x->can('then')) {
      my $sync = Evo::Promise::Sync->new(promise => $self)->try_thenable($x);
      return unless $sync->should_resolve;
      $x = $sync->v;    # and next, but it's already last in loop
      next;
    }

    # 2.3.3.4
    return $self->d_fulfill($x);
  }
}

# reject promise and call traverse with the stack of children
sub d_reject_continue ($self, $reason) {
  $self->d_reject($reason);
  $self->d_traverse;
}

sub d_resolve_continue ($self, $v) {
  $self->d_resolve($v);
  return unless $self->d_settled;
  $self->d_traverse;
}

# breadth-first
sub d_traverse($self) {

  my @stack = ($self);
  while (@stack) {

    my $parent = shift @stack;

    #assert($parent->d_settled);
    my @children = $parent->d_children->@* or next;
    $parent->d_children([]);

    # 2.2.2 - 2.2.7
    my ($pstate, $v) = ($parent->state, $parent->d_v);
    foreach my $cur (@children) {
      my $h = $pstate eq FULFILLED ? $cur->d_fh : $cur->d_rh;
      $cur->d_fh(undef)->d_rh(undef);

      if ($h) {
        my $sub = sub {
          my $x;
          eval { $x = $h->($v); 1 } ? $cur->d_resolve_continue($x) : $cur->d_reject_continue($@);
        };
        $self->postpone($sub);    # 2.2.4, call async
        next;
      }

      $pstate eq FULFILLED ? $cur->d_fulfill($v) : $cur->d_reject($v);
      push @stack, $cur;
    }

  }

}

sub postpone ($self, $fn) {
  &loop_postpone($fn);
}

1;
