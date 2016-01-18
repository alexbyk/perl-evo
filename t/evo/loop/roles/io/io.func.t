package main;
use Evo '-Io::Socket; Test::More; -Loop::Comp; Socket :all; -Lib *';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);


*newloop = *Evo::Loop::Comp::new;

my ($foo, $bar) = (socket_open(), socket_open());
socketpair($foo, $bar, AF_UNIX, SOCK_STREAM, PF_UNSPEC) || die "socketpair: $!";

$foo->handle_non_blocking(1);
$bar->handle_non_blocking(1);

my $buf;
sysread($bar, $buf, 2, length($buf) || 0);

my $loop = newloop();
my $called;

$loop->io_out(
  $foo,
  sub {
    $called++;
    $loop->io_remove_out($foo);
    syswrite $foo, "Hello";
  }
);

$loop->io_in(
  $bar,
  sub {
    $called++ while sysread($bar, $buf, 2, length($buf) || 0);
    $loop->io_remove_in($bar);
  }
);


$loop->start;

# 1 write + He+ll+o
is $called, 4;
is $buf,    "Hello";

done_testing;
