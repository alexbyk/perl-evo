package Evo::Promise::Deferred;
use Evo '-Class *';

has 'promise', ro;
has 'called', optional;

sub reject ($self, $r=undef) {
  return if $self->called;
  $self->called(1)->promise->d_reject_continue($r);
}

sub resolve ($self, $v=undef) {
  return if $self->called;
  $self->called(1)->promise->d_resolve_continue($v);
}

1;
