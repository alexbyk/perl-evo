package Evo::Loop::Role::Io;
use Evo '-Role *';
use Carp 'croak';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);

requires qw(zone_cb update_tick_time);

*io_poll = *IO::Poll::_poll;

has io_data => sub { {} };

use constant SOCKET_IN  => POLLIN | POLLPRI;
use constant SOCKET_OUT => POLLOUT;
use constant SOCKET_ERR => POLLERR | POLLNVAL | POLLHUP;

sub io_count : Role { scalar keys $_[0]->io_data->%* }

my %MAP = (in => SOCKET_IN, out => SOCKET_OUT);
my %OPP = (in => "out", out => "in");

sub _mask_fd {
  my ($self, $handle, $type) = @_;
  croak qq#bad type "$type"# unless my $mask = $MAP{$type};
  my $data = $self->io_data;
  my $fd = fileno $handle or croak "Can't find fileno for $handle";
  return ($mask, $fd);
}

sub io_error($self, $handle, $fn) : Role {
  my $slot = $self->io_data->{fileno($handle)}
    or croak "Install events for $handle before error";
  croak "$handle already has error" if exists $slot->{error};

  $slot->{error} = $self->zone_cb($fn);
}

sub io_in : Role  { handle('in',  @_) }
sub io_out : Role { handle('out', @_) }

sub handle($type, $self, $handle, $fn) {
  my ($mask, $fd) = _mask_fd($self, $handle, $type);
  my $data = $self->io_data;
  croak qq#$handle already has "$type"# if $data->{$fd}{$type};
  $data->{$fd}{$type} = $self->zone_cb($fn);
  $data->{$fd}{mask} |= $mask;
}

sub io_remove_in : Role  { io_remove(in  => @_) }
sub io_remove_out : Role { io_remove(out => @_) }

sub io_remove($type, $self, $handle) {
  my ($mask, $fd) = _mask_fd($self, $handle, $type);
  my $data = $self->io_data;
  croak qq#$handle hasn't "$type"# unless exists $data->{$fd}{$type};

  if (exists $data->{$fd}{$OPP{$type}}) {
    $data->{$fd}{mask} &= ~$mask;
    delete $data->{$fd}{$type};
  }
  else { delete $data->{$fd}; }
}

sub io_remove_all($self, $handle) : Role {
  delete $self->io_data->{fileno $handle};
}

sub io_process($self, $timeout_float=undef) : Role {
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
