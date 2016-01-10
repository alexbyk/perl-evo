package main;
use Evo;
use Test::More;
use Test::Fatal;
use IO::Socket::IP;
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);

{

  package MyLoop;
  use Evo '-Comp *', -Loaded;
  with 'Evo::Loop::Role::Handle';

  sub zone_cb { $_[1] . '-Z' }
}

my $handle = *STDOUT;

is(MyLoop::new->handle_count, 0);

EXCEPTIONS: {
  my $loop = MyLoop::new();
  like exception { $loop->handle($handle, bad => 'IN') }, qr/bad type "bad".+$0/;
  like exception { $loop->handle_remove($handle, 'bad') }, qr/bad type "bad".+$0/;

  like exception { $loop->handle("FOO", in => 'IN') }, qr/fileno.+FOO.+$0/;
  like exception { $loop->handle_remove("FOO", 'in') }, qr/fileno.+FOO.+$0/;

  like exception { $loop->handle($handle, in => 'IN') for 1 .. 2; }, qr/already.+in.+$0/;

  like exception { MyLoop::new->handle_remove($handle, 'in') for 1 .. 2; },
    qr/hasn't.+in.+$0/;

}

ADD: {
  my $loop = MyLoop::new();
  my $data = $loop->handle_data;

  $loop->handle($handle, in => 'IN');
  is $data->{fileno($handle)}{in}, 'IN-Z';
  ok $data->{fileno($handle)}{mask} & (POLLIN | POLLPRI);

  $loop->handle($handle, out => 'OUT');
  is $data->{fileno($handle)}{out}, 'OUT-Z';
  ok $data->{fileno($handle)}{mask} & (POLLOUT);
  is $loop->handle_count, 1;
}

REMOVE: {
  my $loop = MyLoop::new();
  my $data = $loop->handle_data;

  $loop->handle($handle, in  => 'IN');
  $loop->handle($handle, out => 'OUT');

  $loop->handle_remove($handle, 'in');
  ok $data->{fileno($handle)}{mask} & (POLLOUT);
  ok !($data->{fileno($handle)}{mask} & (POLLIN));
  is $loop->handle_count, 1;

  $loop->handle_remove($handle, 'out');
  ok !$data->{fileno($handle)};
  is $loop->handle_count, 0;
}

REMOVE_ALL: {
  my $loop = MyLoop::new();
  my $data = $loop->handle_data;
  $loop->handle($handle, in => 'IN');
  $loop->handle_remove_all($handle);
  ok !keys $data->%*;
}

CATCH_EXC: {
  my $loop = MyLoop::new();
  $loop->handle($handle, in => sub { });
  like exception { $loop->handle_catch($handle, 'ERR') for 1 .. 2 }, qr/already.+catch.+$0/i;

  like exception { MyLoop::new->handle_catch($handle, 'ERR') }, qr/install.+event.+catch.+$0/i;

  $loop = MyLoop::new();
  $loop->handle($handle, in => sub { });
  $loop->handle_catch($handle, 'CATCH');
  is $loop->handle_data->{fileno($handle)}->{catch}, 'CATCH-Z';
}


done_testing;
