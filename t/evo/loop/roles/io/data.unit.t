package main;
use Evo;
use Test::More;
use Test::Fatal;
use IO::Socket::IP;
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);

{

  package MyLoop;
  use Evo '-Comp *', -Loaded;
  with 'Evo::Loop::Role::Io';
  sub update_tick_time { }

  sub zone_cb { $_[1] . '-Z' }
}

my $handle = *STDOUT;

is(MyLoop::new->io_count, 0);

EXCEPTIONS: {
  my $loop = MyLoop::new();

  like exception { $loop->io_in("FOO", 'IN') }, qr/fileno.+FOO.+$0/;
  like exception { $loop->io_remove_in("FOO") }, qr/fileno.+FOO.+$0/;

  like exception { $loop->io_in($handle, 'IN') for 1 .. 2; }, qr/already.+in.+$0/;

  like exception { MyLoop::new->io_remove_in($handle) for 1 .. 2; }, qr/hasn't.+in.+$0/;

}

ADD: {
  my $loop = MyLoop::new();
  my $data = $loop->io_data;

  $loop->io_in($handle, 'IN');
  is $data->{fileno($handle)}{in}, 'IN-Z';
  ok $data->{fileno($handle)}{mask} & (POLLIN | POLLPRI);

  $loop->io_out($handle, 'OUT');
  is $data->{fileno($handle)}{out}, 'OUT-Z';
  ok $data->{fileno($handle)}{mask} & (POLLOUT);
  is $loop->io_count, 1;
}

REMOVE: {
  my $loop = MyLoop::new();
  my $data = $loop->io_data;

  $loop->io_in($handle, 'IN');
  $loop->io_out($handle, 'OUT');

  $loop->io_remove_in($handle);
  ok $data->{fileno($handle)}{mask} & (POLLOUT);
  ok !($data->{fileno($handle)}{mask} & (POLLIN));
  is $loop->io_count, 1;

  $loop->io_remove_out($handle);
  ok !$data->{fileno($handle)};
  is $loop->io_count, 0;
}

REMOVE_ALL: {
  my $loop = MyLoop::new();
  my $data = $loop->io_data;
  $loop->io_in($handle, 'IN');
  $loop->io_remove_all($handle);
  ok !keys $data->%*;
}

CATCH_EXC: {
  my $loop = MyLoop::new();
  $loop->io_in($handle, sub { });
  like exception { $loop->io_error($handle, 'ERR') for 1 .. 2 }, qr/already.+error.+$0/i;

  like exception { MyLoop::new->io_error($handle, 'ERR') }, qr/install.+event.+error.+$0/i;

  $loop = MyLoop::new();
  $loop->io_in($handle, sub { });
  $loop->io_error($handle, 'CATCH');
  is $loop->io_data->{fileno($handle)}->{error}, 'CATCH-Z';
}


done_testing;
