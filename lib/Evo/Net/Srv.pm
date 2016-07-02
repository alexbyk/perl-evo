package Evo::Net::Srv;
use Evo '-Class *';

with '::Role', -Ee;

sub ee_events {qw(srv_accept srv_error)}

sub srv_handle_accept ($self, $sock) : Over {
  $self->emit(srv_accept => $sock);
  $sock;
}

sub srv_handle_error ($self, $conn, $err) : Over {
  Evo::Net::Srv::Role::srv_handle_error($self, $conn, $err);
  $self->emit(srv_error => $conn, $err);
}

1;

=head1 SYNOPSYS

  use Evo '-Net::Srv; -Loop *';

  my $srv = Evo::Net::Srv->new();
  my $listen_socket = $srv->srv_listen(ip => '*', port => 8080);

  $srv->on(
    srv_accept => sub($srv, $sock) {
      my ($ip, $port) = $sock->io_remote;
      say sprintf("New connection from %s[%s], [%s]", $ip, $port, scalar localtime);
    }
  );

  loop_start;

=head1

Mostly for testing purposes. For writing servers, see L<Evo::Net::Srv::Role>

=cut
