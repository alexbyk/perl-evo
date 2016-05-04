package Evo::Net::Srv::Role;
use Evo '-Role *; -Loop *; -Io *; -Lib::Net *; Carp croak';
use Errno qw( EAGAIN EWOULDBLOCK );
use Socket qw( AF_INET AF_INET6 SOL_SOCKET SOMAXCONN);
use Scalar::Util 'weaken';
use Hash::Util::FieldHash qw(fieldhash id_2obj);

has srv_is_running => 1;
has srv_acceptors => sub { [] };

has _srv_conn_data => sub { fieldhash my %hash; \%hash }, is => 'ro';

sub srv_connectionss($s, @conns) : Role {
  my $data = $s->_srv_conn_data;
  return map { id_2obj $_} keys %$data unless @conns;
  $data->{$_}++ for @conns;
}

sub srv_handle_error($self, $sock, $err) : Role { $self->srv_remove_socket($sock); }
sub srv_handle_accept($self, $sock) : Role      {$sock}

sub srv_start_watching($self, $sock) : Role {
  loop_io_in $sock, sub { $self->srv_accept($sock) };
  loop_io_error $sock, sub { $self->srv_handle_error($sock, "Unknown") };
}
sub srv_stop_watching($self, $sock) : Role { loop_io_remove_all $sock; }

sub srv_stop($self) : Role {
  croak "already stopped" unless $self->srv_is_running;
  $self->srv_is_running(0);
  $self->srv_stop_watching($_) for $self->srv_acceptors->@*;
}

sub srv_start($self) : Role {
  croak "already running" if $self->srv_is_running;
  $self->srv_is_running(1);
  $self->srv_start_watching($_) for $self->srv_acceptors->@*;
}

sub srv_remove_socket($self, $sock) : Role {
  $self->srv_acceptors([grep { $_ != $sock } $self->srv_acceptors->@*]);
}

sub srv_accept($self, $sock) : Role {
  my $child;
  while ($child = $sock->io_accept()) {

    # handle accept should return new socket, probably bless this one
    $child = $self->srv_handle_accept($child->io_non_blocking(1));
    $self->srv_connectionss($child);
  }
  return if $! == EAGAIN || $! == EWOULDBLOCK;
  $self->srv_handle_error($sock, $!);
}


sub srv_listen($self, %opts) : Role {
  my @conn_keys = qw(port ip backlog reuseport);
  my %conn      = %opts{@conn_keys};
  delete $opts{$_} for @conn_keys;

  croak "unknown options: " . join(',', keys %opts) if keys %opts;

  my $sock = io_listen(%conn);


  push $self->srv_acceptors->@*, $sock;
  $self->srv_start_watching($sock) if $self->srv_is_running;
  $sock;
}


1;

=head1

Each class should provide C<srv_handle_accept> and may want override C<srv_handle_error>

=head2 srv_listen

Create a socket and call listen.

=over

=item ip

Ip to bind to. Use C<'0.0.0.0'> or C<'::'> for "all"

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
