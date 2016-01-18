use Evo 'Test::More; -Io *; File::Temp tempfile';

HANDLE: {
  my $str = "hello";
  my ($fh, $filename) = tempfile();
  my $io = io_open('>', $filename);
  ok fileno $io;
  ok $io->io_non_blocking(1);

  # anon
  $io = io_open_anon;
  ok fileno $io;
  ok $io->io_non_blocking(1);
  ok !$io->io_non_blocking(0)->io_non_blocking;
  ok $io->io_non_blocking(1)->io_non_blocking;
}

SOCKET: {
  my $sock = io_socket();
  ok $sock->io_non_blocking;
  ok fileno $sock;
}

done_testing;
