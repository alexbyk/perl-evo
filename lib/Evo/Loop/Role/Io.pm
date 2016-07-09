package Evo::Loop::Role::Io;
use Evo '-Class *, -new';
use Carp 'croak';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);

requires qw(zone_cb update_tick_time);

*io_poll = *IO::Poll::_poll;

has io_data => sub { {} };

use constant SOCKET_IN  => POLLIN | POLLPRI;
use constant SOCKET_OUT => POLLOUT;
use constant SOCKET_ERR => POLLERR | POLLNVAL | POLLHUP;

sub io_count { scalar keys $_[0]->io_data->%* }


sub io_in    { handle(in    => SOCKET_IN,  @_) }
sub io_out   { handle(out   => SOCKET_OUT, @_) }
sub io_error { handle(error => SOCKET_ERR, @_) }

sub handle ($type, $mask, $self, $handle, $fn) {
  my $fd = fileno $handle or croak "Can't find fileno for $handle";
  my $data = $self->io_data;
  croak qq#$handle already has "$type"# if $data->{$fd}{$type};
  $data->{$fd}{$type} = $self->zone_cb($fn);
  $data->{$fd}{mask} |= $mask;
}

sub io_remove_in    { io_remove(in    => SOCKET_IN,  @_) }
sub io_remove_out   { io_remove(out   => SOCKET_OUT, @_) }
sub io_remove_error { io_remove(error => SOCKET_ERR, @_) }

# if no events, delete slot, else - upgrade mask
sub io_remove ($type, $mask, $self, $handle) {
  my $fd = fileno $handle or croak "Can't find fileno for $handle";
  my $data = $self->io_data;
  croak qq#$handle hasn't "$type"# unless exists $data->{$fd}{$type};

  if (keys $data->{$fd}->%* > 2) {    # mask + cur => last
    $data->{$fd}{mask} &= ~$mask;
    delete $data->{$fd}{$type};
  }
  else { delete $data->{$fd}; }
}

sub io_remove_all ($self, $handle) {
  delete $self->io_data->{fileno $handle};
}

sub io_remove_fd ($self, $fd) {
  delete $self->io_data->{$fd};
}

sub io_process ($self, $timeout_float = undef) {
  my $data = $self->io_data;
  return unless keys $data->%*;
  my $timeout_ms = $timeout_float ? int($timeout_float * 1000) : 0;
  my @map = map { ($_ => $data->{$_}->{mask}) } keys $data->%*;
  if (io_poll($timeout_ms, @map)) {
    $self->update_tick_time;    # because events can call timers with uotdated time
    my $data = $self->io_data;
    while (my ($fd, $revents) = splice @map, 0, 2) {
      my $slot = $data->{$fd};
      $slot->{in}->()    if $revents & SOCKET_IN;
      $slot->{out}->()   if $revents & SOCKET_OUT;
      $slot->{error}->() if ($revents & SOCKET_ERR) && $slot->{error};
    }
  }
}

1;
