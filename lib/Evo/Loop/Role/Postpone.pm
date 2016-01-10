package Evo::Loop::Role::Postpone;
use Evo '-Comp::Role *';

requires qw(zone_cb);

has data_postpone => default => sub { [] };

sub postpone_count($self) : Role { $self->data_postpone->@* }
sub postpone($self, $fn) : Role { push $self->data_postpone->@*, $self->zone_cb($fn); }

sub postpone_process($self) : Role {
  my $postpone = $self->data_postpone;
  shift(@$postpone)->() while @$postpone;
}

1;
