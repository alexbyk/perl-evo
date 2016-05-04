package main;
use Evo '-Loop::Class; Test::More; Test::Fatal; IO::Socket::IP';

use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);


open(my $handle, '<', undef) or plan skip_all => "$!";

is(Evo::Loop::Class::new->io_count, 0);

EXCEPTIONS: {
  my $loop = Evo::Loop::Class::new();

  like exception { $loop->io_in("FOO", 'IN') }, qr/fileno.+FOO.+$0/;
  like exception { $loop->io_remove_in("FOO") }, qr/fileno.+FOO.+$0/;

  like exception { $loop->io_in($handle, 'IN') for 1 .. 2; }, qr/already.+in.+$0/;
  like exception { Evo::Loop::Class::new->io_remove_in($handle) for 1 .. 2; }, qr/hasn't.+in.+$0/;
}

ADD_REMOVE: {
  my $loop = Evo::Loop::Class::new();
  my $data = $loop->io_data;

  $loop->io_in($handle, 'IN');
  ok $data->{fileno($handle)}{mask} & (POLLIN | POLLPRI);
  $loop->io_out($handle, 'OUT');
  ok $data->{fileno($handle)}{mask} & POLLOUT;
  $loop->io_error($handle, 'ERR');
  ok $data->{fileno($handle)}{mask} & POLLERR;

  is $loop->io_count, 1;
  $loop->io_remove_in($handle);
  $loop->io_remove_out($handle);
  ok !($data->{fileno($handle)}{mask} & (POLLIN | POLLPRI));
  ok !($data->{fileno($handle)}{mask} & POLLOUT);
  ok $data->{fileno($handle)}{mask} & POLLERR;

  $loop->io_remove_error($handle);
  is $loop->io_count, 0;
}

REMOVE_ALL: {
  my $loop = Evo::Loop::Class::new();
  my $data = $loop->io_data;

  $loop->io_in($handle, 'IN');
  $loop->io_remove_all($handle);
  is $loop->io_count, 0;

  $loop->io_in($handle, 'IN');
  $loop->io_remove_fd(fileno $handle);
  is $loop->io_count, 0;
}

done_testing;
