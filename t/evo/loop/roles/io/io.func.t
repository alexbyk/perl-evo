package main;
use Evo '-Net::Socket; Test::More; -Loop::Comp; Socket :all';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);


*newloop = *Evo::Loop::Comp::new;

my ($foo, $bar) = (Evo::Net::Socket::new(), Evo::Net::Socket::new());
socketpair($foo, $bar, AF_UNIX, SOCK_STREAM, PF_UNSPEC) || die "socketpair: $!";

$foo->io_non_blocking(1);
$bar->io_non_blocking(1);

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
