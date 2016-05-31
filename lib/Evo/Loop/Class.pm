package Evo::Loop::Class;
use Evo -Class, '-Lib steady_time; List::Util first; Time::HiRes usleep; Carp croak';

# pay attention. One for all and limited (but big enough)
my $UID = 0;
sub gen_id { $UID++ }

has is_running => 0;
has tick_time => \&steady_time, is => 'rw';

with 'Evo::Loop::Role::Zone', 'Evo::Loop::Role::Timer', 'Evo::Loop::Role::Io',
  'Evo::Loop::Role::Postpone';

sub update_tick_time { shift->tick_time(steady_time()); }

# return number of event, or 0 if no events left and we can stop
sub tick($self) {
  $self->update_tick_time();

  my $io_count       = $self->io_count;
  my $timer_count    = $self->timer_count;
  my $postpone_count = $self->postpone_count;
  return unless $postpone_count || $io_count || $timer_count;

  $self->timer_process();
  $self->io_process();
  $self->postpone_process();

  return $self->io_count + $self->timer_count + $self->postpone_count;
}

# sleep in usleep or in io_process. Assumming there is at least some event
sub maybe_sleep($self) {
  $self->update_tick_time;
  my ($tc, $sc) = ($self->timer_count(), $self->io_count());

  if    ($sc && $tc)  { $self->io_process($self->timer_calculate_timeout()); }
  elsif ($sc && !$tc) { $self->io_process(-1); }
  elsif (!$sc && $tc) {
    my $timeout = int($self->timer_calculate_timeout * 1_000_000);
    usleep($timeout) if $timeout;
  }
  else { die "something wrong, no events" }
}

sub stop($self) { $self->is_running(0) }

sub start($self) {
  $self->is_running(1);
  local $SIG{PIPE} = 'IGNORE';
  $self->maybe_sleep while $self->tick && $self->is_running;
}


# postpone callback with a previous level
sub escape_to_level ($self, $level, $cb) : Public {
  my $data = $self->zone_data;
  croak "Bad level $level (max ${\$self->zone_level})" unless $level < $self->zone_level;
  push $self->postpone_queue->@*, sub {
    local $data->{middleware} = [map { [$_->@*] } @{$data->{middleware}}[0 .. $level]];
    $cb->();
  };
}


1;
