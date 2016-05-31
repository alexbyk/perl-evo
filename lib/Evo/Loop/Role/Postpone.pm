package Evo::Loop::Role::Postpone;
use Evo '-Class::Role *';

requires qw(zone_cb);

has postpone_queue => default => sub { [] };

sub postpone_count($self) : Public { $self->postpone_queue->@* }
sub postpone ($self, $fn) : Public { push $self->postpone_queue->@*, $self->zone_cb($fn); }

sub postpone_process($self) : Public {
  my $postpone = $self->postpone_queue;
  shift(@$postpone)->() while @$postpone;
}

1;
