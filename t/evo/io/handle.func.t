use Evo 'Test::More; -Loop *; -Io::Handle; File::Temp tempfile';

BEGIN {
  *open_nb      = *Evo::Io::Handle::open_nb;
  *open_anon_nb = *Evo::Io::Handle::open_anon_nb;
}

plan skip_all => 'Looks like a ro system' unless open_anon_nb;


OPEN: {
  my $str = "hello";
  my ($fh, $filename) = tempfile();
  my $io = open_nb('>', $filename);
  ok fileno $io;
  ok $io->handle_non_blocking(1);

  # anon
  $io = open_anon_nb ok fileno $io;
  ok $io->handle_non_blocking(1);
}

WATCH_IGNORE: {
  my $loop = Evo::Loop::Comp::new();
  Evo::Loop::Comp::realm $loop, sub {
    my $io = open_anon_nb();
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
    my $io = open_anon_nb();
    loop_io_in $io,  sub { };
    loop_io_out $io, sub { };
    is $loop->io_count, 1;
  };

  is $loop->io_count, 0;
}

done_testing;
