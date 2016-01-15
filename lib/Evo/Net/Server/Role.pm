package Evo::Net::Server::Role;
use Evo '-Comp::Role *; -Loop *; -Net::Socket; -Net::Util *; Carp croak';
use Errno qw( EAGAIN EWOULDBLOCK );
use Socket qw( AF_INET AF_INET6 SOL_SOCKET SOMAXCONN);
use Scalar::Util 'weaken';
use Hash::Util::FieldHash qw(fieldhash id_2obj);

requires qw(handle_accept emit);

has s_is_running => 1;
has s_sockets => sub { [] };

has _s_conn_data => sub { fieldhash my %hash; \%hash }, is => 'ro';

sub s_streams($s, @conns) : Role {
  my $data = $s->_s_conn_data;
  return map { id_2obj $_} keys %$data unless @conns;
  $data->{$_}++ for @conns;
}

# nodelay => 1, reuseaddr => 1
sub _gen_sock($family, $o) {
  my $sock
    = Evo::Net::Socket::new()->socket_open($family)->socket_nodelay(delete $o->{nodelay} // 1)
    ->socket_reuseaddr(delete $o->{reuseaddr} // 1)->non_blocking(1);

  # not always supported
  $sock->socket_reuseport(1) if delete $o->{reuseport};
  $sock;
}

sub s_handle_error($self, $sock, $err) : Role {
  $self->s_remove_socket($sock)->emit(s_error => $err);
}

sub s_start_watching($self, $sock) : Role {
  loop_handle_in $sock, sub { $self->s_accept_socket($sock) };
  loop_handle_error $sock, sub { $self->s_handle_error($sock, "Unknown") };
}
sub s_stop_watching($self, $sock) : Role { loop_handle_remove_all $sock; }

sub s_stop($self) : Role {
  croak "already stopped" unless $self->s_is_running;
  $self->s_is_running(0);
  $self->s_stop_watching($_) for $self->s_sockets->@*;
}

sub s_start($self) : Role {
  croak "already running" if $self->s_is_running;
  $self->s_is_running(1);
  $self->s_start_watching($_) for $self->s_sockets->@*;
}

sub s_remove_socket($self, $sock) : Role {
  $self->s_sockets([grep { $_ != $sock } $self->s_sockets->@*]);
}

sub s_accept_socket($self, $sock) : Role {
  my $child;
  while ($child = $sock->socket_accept()) {

    # handle accept should return new socket, probably bless this one
    my $stream = $self->handle_accept($child->non_blocking(1));
    $self->s_streams($stream);
    die "$stream should privide emit" unless $stream->can('emit');
  }
  return if $! == EAGAIN || $! == EWOULDBLOCK;
  $self->s_handle_error($sock, $!);
}


sub s_listen($self, %opts) : Role {
  my $port    = delete $opts{port}    || 0;
  my $backlog = delete $opts{backlog} || SOMAXCONN;
  my $ip      = delete $opts{ip}      || croak "Provide ip or * for wildcards";
  my $remaining = \%opts;

  my $sock;

  if (($ip ne '*') || $port) {
    my ($saddr, $family) = net_gen_saddr_family($ip, $port);
    $sock = _gen_sock($family, $remaining)->socket_bind($saddr);
  }
  else {
    $sock = _gen_sock(AF_INET6, $remaining);
  }

  croak "unknown options: " . join(',', keys %$remaining) if keys %$remaining;

  $sock->socket_listen($backlog);
  push $self->s_sockets->@*, $sock;
  $self->s_start_watching($sock) if $self->s_is_running;
  $sock;
}


1;

=head2 s_listen

Create a socket and call listen.

=over

=item ip

Ip to bind to. C<'*'> or C<'::'> for "all", C<'0.0.0.0.> for ipv4 only.

=item port

Port to bind to. Without this option a free port will be generated

=item backlog

Default C<SOMAXCONN>

=item nodelay

=item requseport

=item reuseaddr

Default C<1>

=back

=cut
