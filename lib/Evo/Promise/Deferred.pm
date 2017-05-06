package Evo::Promise::Deferred;
use Evo '-Class *';

has 'promise', ro;
has 'called', optional;

sub reject ($self, $r) {
  return if $self->called;
  $self->called(1)->promise->d_reject_continue($r);
}

sub resolve ($self, $v) {
  return if $self->called;
  $self->called(1)->promise->d_resolve_continue($v);
}

1;
