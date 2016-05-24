package Evo::Loop::Role::Postpone;
use Evo '-Class::Role *';

requires qw(zone_cb);

has data_postpone => default => sub { [] };

sub postpone_count($self) : Public { $self->data_postpone->@* }
sub postpone ($self, $fn) : Public { push $self->data_postpone->@*, $self->zone_cb($fn); }

sub postpone_process($self) : Public {
  my $postpone = $self->data_postpone;
  shift(@$postpone)->() while @$postpone;
}

1;
