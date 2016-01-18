use Evo 'Test::More; -Net::Srv; -Lib *';

my $srv = Evo::Net::Srv::new();

my $called = 0;
my ($sock, $conn) = (socket_open(), socket_open());


$srv->on(
  srv_accept => sub($_srv, $_sock) {
    $called++;
    is $_srv,  $srv;
    is $_sock, $sock;
  }
  )->on(
  srv_error => sub($_srv, $_conn, $err) {
    is $_srv,  $srv;
    is $_conn, $conn;
    is $err,   "MyErr";
    $called++;
  }
  );

$sock = $srv->srv_handle_accept($sock);

$srv->srv_sockets([$conn]);
$sock = $srv->srv_handle_error($conn, "MyErr");
ok !$srv->srv_sockets->@*;

is $called, 2;

done_testing;
