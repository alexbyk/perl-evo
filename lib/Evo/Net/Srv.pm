package Evo::Net::Srv;
use Evo '-Comp *';

with ':Role', -Ee;

sub ee_events {qw(srv_accept srv_error)}

sub srv_handle_accept($self, $sock) : Override {
  $self->emit(srv_accept => $sock);
  $sock;
}

sub srv_handle_error($self, $conn, $err) : Override {
  Evo::Net::Srv::Role::srv_handle_error($self, $conn, $err);
  $self->emit(srv_error => $conn, $err);
}

1;
