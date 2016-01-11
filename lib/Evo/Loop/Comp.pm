package Evo::Loop::Comp;
use Evo '-Comp *', '-Lib steady_time', '-Export *; -Realm *';
use List::Util 'first';
use Time::HiRes 'usleep';

has is_running => 0;
has tick_time => \&steady_time, is => 'rw';

with 'Evo::Loop::Role::Zone', 'Evo::Loop::Role::Timer', 'Evo::Loop::Role::Handle',
  'Evo::Loop::Role::Postpone';

sub update_tick_time { shift->tick_time(steady_time()); }

# return number of event, or 0 if no events left and we can stop
sub tick($self) {
  $self->update_tick_time();

  my $handle_count   = $self->handle_count;
  my $timer_count    = $self->timer_count;
  my $postpone_count = $self->postpone_count;
  return unless $postpone_count || $handle_count || $timer_count;

  $self->timer_process();
  $self->handle_process();
  $self->postpone_process();

  return $self->handle_count + $self->timer_count + $self->postpone_count;
}

# sleep in usleep or in handle_process. Assumming there is at least some event
sub maybe_sleep($self) {
  $self->update_tick_time;
  my ($tc, $sc) = ($self->timer_count(), $self->handle_count());

  if    ($sc && $tc)  { $self->handle_process($self->timer_calculate_timeout()); }
  elsif ($sc && !$tc) { $self->handle_process(-1); }
  elsif (!$sc && $tc) {
    my $timeout = int($self->timer_calculate_timeout * 1_000_000);
    usleep($timeout) if $timeout;
  }
  else { die "something wrong, no events" }
}


sub start($self) { $self->maybe_sleep while $self->tick; }

1;
