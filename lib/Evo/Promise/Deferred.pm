package Evo::Promise::Deferred;
use Evo '-Class *';

has 'promise', required => 1, is => 'ro';
has 'called';

sub reject ($self, $r) {
  return if $self->called;
  $self->called(1)->promise->d_reject_continue($r);
}

sub resolve ($self, $v) {
  return if $self->called;
  $self->called(1)->promise->d_resolve_continue($v);
}

1;
