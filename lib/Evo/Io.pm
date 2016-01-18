package Evo::Io;
use Evo '-Export *; Symbol gensym; :Handle; :Socket';
use Socket qw( SOCK_STREAM AF_INET AF_INET6 IPPROTO_TCP);

our @CARP_NOT = qw(Evo::Net::Server::Role);

sub io_open($mode, $expr, @list) : Export {
  my $fh = Evo::Io::Handle::init(gensym());
  open($fh, $mode, $expr, @list) || die "open: $!";    ## no critic
  $fh->io_non_blocking(1);
}

sub io_open_anon : Export {
  my $fh = Evo::Io::Handle::init(gensym());
  open($fh, '>', undef);
  $fh->io_non_blocking(1);
}


sub io_socket : Export {
  my ($family, $type, $proto) = @_;
  $proto ||= IPPROTO_TCP;
  my $s = gensym;
  socket($s, $family || AF_INET6, $type || SOCK_STREAM, $proto) || die "socket: $!";
  Evo::Io::Socket::init($s)->io_non_blocking(1);
  $s->io_nodelay(1) if $proto == IPPROTO_TCP;
  $s;
}

1;
