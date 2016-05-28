use Evo 'Test::More; -Net::Srv; -Io *';

my $srv = Evo::Net::Srv->new();

my $called = 0;
my ($sock, $conn) = (io_socket(), io_socket());


$srv->on(
  srv_accept => sub ($_srv, $_sock) {
    $called++;
    is $_srv,  $srv;
    is $_sock, $sock;
  }
  )->on(
  srv_error => sub ($_srv, $_conn, $err) {
    is $_srv,  $srv;
    is $_conn, $conn;
    is $err,   "MyErr";
    $called++;
  }
  );

$sock = $srv->srv_handle_accept($sock);

$srv->srv_acceptors([$conn]);
$sock = $srv->srv_handle_error($conn, "MyErr");
ok !$srv->srv_acceptors->@*;

is $called, 2;

done_testing;
