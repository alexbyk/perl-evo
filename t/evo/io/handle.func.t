use Evo 'Test::More; -Loop *; -Io *';

plan skip_all => 'Looks like a ro system' unless io_open_anon;


WATCH_IGNORE: {
  my $loop = Evo::Loop::Comp::new();
  Evo::Loop::Comp::realm $loop, sub {
    my $io = io_open_anon();
    loop_io_in $io,  sub { };
    loop_io_out $io, sub { };
    is $loop->io_count, 1;
    loop_io_remove_in $io;
    loop_io_remove_out $io;
    is $loop->io_count, 0;
  };
}

DESTROY: {
  my $loop = Evo::Loop::Comp::new();
  Evo::Loop::Comp::realm $loop, sub {
    my $io = io_open_anon();
    loop_io_in $io,  sub { };
    loop_io_out $io, sub { };
    is $loop->io_count, 1;
  };

  is $loop->io_count, 0;
}

done_testing;
