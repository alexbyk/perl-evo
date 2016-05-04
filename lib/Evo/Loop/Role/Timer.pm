package Evo::Loop::Role::Timer;
use Evo '-Role *; Carp croak';
use List::Util 'first';

requires qw(zone_cb tick_time);

has timer_need_sort => is => 'rw';
has timer_queue => sub { [] };

# [time, zcb]
# alwais check timer_count before timer_process or calculate_timeout

sub timer_count : Role { scalar $_[0]->timer_queue->@* }

sub timer : Role {
  croak "Not enought arguments" if @_ < 3;
  my ($self, $after, $cb, $period) = (shift, shift, pop, shift);
  croak "Negative period!" if $period && $period < 0;
  my $zcb = $self->zone_cb($cb);

  push $self->timer_need_sort(1)->timer_queue->@*,
    my $slot = [$self->tick_time + $after, $zcb, $period ? $period : ()];
  $slot;
}

sub timer_remove ($self, $ref) : Role {
  my $que = $self->timer_queue;

  defined(my $index = first { $que->[$_] == $ref } 0 .. $#$que) or return;
  splice $que->@*, $index, 1;
}

sub timer_sort_if_needed($self) : Role {
  return unless $self->timer_need_sort;
  my $timer_queue = $self->timer_queue;
  $timer_queue->@* = sort { $a->[0] <=> $b->[0] } $timer_queue->@*;
  $self->timer_need_sort(0);
}

# queue is a list of unsorted timers. Queue becomes sorted at the beginning.
# Adding timer makes queue unsorted again.
# because timers are sorted, process till first future timer
sub timer_process($self) : Role {
  $self->timer_sort_if_needed();
  my $time        = $self->tick_time;
  my $timer_queue = $self->timer_queue;

  while (@$timer_queue && $timer_queue->[0][0] < $time) {
    my $slot = shift(@$timer_queue);
    if ($slot->[2]) {    # periodic
      $slot->[0] = $slot->[2] + $time;
      push $timer_queue->@*, $slot;
    }
    $slot->[1]->();
  }
}


# calculates a timeout the app can sleep without missing timer
# assumes that have at least one timer. Calls sort_if_needed
# returns ms (1s/1000), >=0
sub timer_calculate_timeout($self) : Role {
  $self->timer_sort_if_needed();
  my $timeout = ($self->timer_queue->[0][0] - $self->tick_time);
  return $timeout > 0 ? $timeout : 0;
}

1;
