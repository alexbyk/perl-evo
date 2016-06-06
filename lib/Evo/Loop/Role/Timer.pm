package Evo::Loop::Role::Timer;
use Evo -Class::Role, 'Carp croak; List::Util first';

requires qw(zone_cb tick_time gen_id);

has timer_need_sort => is => 'rw';
has timer_queue => sub { [] };

# alwais check timer_count before timer_process or calculate_timeout

sub timer_count { scalar $_[0]->timer_queue->@* }


sub timer_periodic ($self, $after, $period, $cb) {
  croak "Negative period!" if $period && $period < 0;
  push $self->timer_need_sort(1)->timer_queue->@*,
    {
    when   => $self->tick_time + $after,
    cb     => $self->zone_cb($cb),
    id     => my $id = $self->gen_id,
    period => $period
    };
  $id;
}

sub timer ($self, $after, $cb) {
  push $self->timer_need_sort(1)->timer_queue->@*,
    {when => $self->tick_time + $after, cb => $self->zone_cb($cb), id => my $id = $self->gen_id};
  $id;
}

sub timer_remove ($self, $id) {
  my $que = $self->timer_queue;
  defined(my $index = first { $que->[$_]{id} == $id } 0 .. $#$que) or return;
  splice $que->@*, $index, 1;
}

sub timer_sort_if_needed($self) {
  return unless $self->timer_need_sort;
  my $timer_queue = $self->timer_queue;
  $timer_queue->@* = sort { $a->{when} <=> $b->{when} } $timer_queue->@*;
  $self->timer_need_sort(0);
}

# queue is a list of unsorted timers. Queue becomes sorted at the beginning.
# Adding timer makes queue unsorted again.
# because timers are sorted, process till first future timer
sub timer_process($self) {
  $self->timer_sort_if_needed();
  my $time        = $self->tick_time;
  my $timer_queue = $self->timer_queue;

  while (@$timer_queue && $timer_queue->[0]{when} < $time) {
    my $slot = shift(@$timer_queue);
    if ($slot->{period}) {    # periodic
      $slot->{when} = $slot->{period} + $time;
      push $timer_queue->@*, $slot;
    }
    $slot->{cb}->();
  }
}


# calculates a timeout the app can sleep without missing timer
# assumes that have at least one timer. Calls sort_if_needed
# returns ms (1s/1000), >=0
sub timer_calculate_timeout($self) {
  $self->timer_sort_if_needed();
  my $timeout = ($self->timer_queue->[0]{when} - $self->tick_time);
  return $timeout > 0 ? $timeout : 0;
}

1;
