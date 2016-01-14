package Evo::Loop::Role::Handle;
use Evo '-Comp::Role *';
use Carp 'croak';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);

requires qw(zone_cb update_tick_time);

*handle_poll = *IO::Poll::_poll;

has handle_data => sub { {} };

use constant SOCKET_IN  => POLLIN | POLLPRI;
use constant SOCKET_OUT => POLLOUT;
use constant SOCKET_ERR => POLLERR | POLLNVAL | POLLHUP;

sub handle_count : Role { scalar keys $_[0]->handle_data->%* }

my %MAP = (in => SOCKET_IN, out => SOCKET_OUT);
my %OPP = (in => "out", out => "in");

sub _mask_fd {
  my ($self, $handle, $type) = @_;
  croak qq#bad type "$type"# unless my $mask = $MAP{$type};
  my $data = $self->handle_data;
  my $fd = fileno $handle or croak "Can't find fileno for $handle";
  return ($mask, $fd);
}

sub handle_error($self, $handle, $fn) : Role {
  my $slot = $self->handle_data->{fileno($handle)}
    or croak "Install events for $handle before error";
  croak "$handle already has error" if exists $slot->{error};

  $slot->{error} = $self->zone_cb($fn);
}

sub handle_in : Role  { handle('in',  @_) }
sub handle_out : Role { handle('out', @_) }

sub handle($type, $self, $handle, $fn) {
  my ($mask, $fd) = _mask_fd($self, $handle, $type);
  my $data = $self->handle_data;
  croak qq#$handle already has "$type"# if $data->{$fd}{$type};
  $data->{$fd}{$type} = $self->zone_cb($fn);
  $data->{$fd}{mask} |= $mask;
}

sub handle_remove_in : Role  { handle_remove(in  => @_) }
sub handle_remove_out : Role { handle_remove(out => @_) }

sub handle_remove($type, $self, $handle) {
  my ($mask, $fd) = _mask_fd($self, $handle, $type);
  my $data = $self->handle_data;
  croak qq#$handle hasn't "$type"# unless exists $data->{$fd}{$type};

  if (exists $data->{$fd}{$OPP{$type}}) {
    $data->{$fd}{mask} &= ~$mask;
    delete $data->{$fd}{$type};
  }
  else { delete $data->{$fd}; }
}

sub handle_remove_all($self, $handle) : Role {
  delete $self->handle_data->{fileno $handle};
}

sub handle_process($self, $timeout_float=undef) : Role {
  my $data = $self->handle_data;
  return unless keys $data->%*;
  my $timeout_ms = $timeout_float ? int($timeout_float * 1000) : 0;
  my @map = map { ($_ => $data->{$_}->{mask}) } keys $data->%*;
  if (handle_poll($timeout_ms, @map)) {
    $self->update_tick_time;    # because events can call timers with uotdated time
    my $data = $self->handle_data;
    while (my ($fd, $revents) = splice @map, 0, 2) {
      my $slot = $data->{$fd};
      $slot->{in}->()    if $revents & SOCKET_IN;
      $slot->{out}->()   if $revents & SOCKET_OUT;
      $slot->{error}->() if ($revents & SOCKET_ERR) && $slot->{error};
    }
  }
}

1;
