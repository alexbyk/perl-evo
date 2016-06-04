use Evo '-Io *; -Loop *; Test::More; Socket :all; -Lib *';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);
use Test::Evo::Helpers 'HAS_O_NONBLOCK';

plan skip_all => "Hasn't O_NONBLOCK"      unless HAS_O_NONBLOCK();
plan skip_all => 'Looks like a ro system' unless io_open_anon;

sub newloop { Evo::Loop::Class->new; }

my ($foo, $bar) = (io_socket(), io_socket());
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


# WATCH_IGNORE_DESTROY
WATCH_IGNORE: {
  local $Evo::Loop::SINGLE = my $loop = Evo::Loop::Class->new();
  my $io = io_open_anon();
  loop_io_in $io,  sub { };
  loop_io_out $io, sub { };
  is $loop->io_count, 1;
  loop_io_remove_in $io;
  loop_io_remove_out $io;
  is $loop->io_count, 0;
}

DESTROY: {
  local $Evo::Loop::SINGLE = my $loop = Evo::Loop::Class->new();


SCOPE: {
    my $io = io_open_anon();
    loop_io_in $io,  sub { };
    loop_io_out $io, sub { };
    is $loop->io_count, 1;
  }

  is $loop->io_count, 0;
}


done_testing;
