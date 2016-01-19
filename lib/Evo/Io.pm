package Evo::Io;
use Evo '-Export *; -Lib::Net *; Symbol gensym; :Handle; :Socket; Carp croak';
use Socket qw( SOCK_STREAM AF_INET AF_INET6 IPPROTO_TCP SOMAXCONN);

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


sub io_listen(%opts) : Export {
  my $port      = delete $opts{port}      || 0;
  my $backlog   = delete $opts{backlog}   || SOMAXCONN;
  my $ip        = delete $opts{ip}        || croak "Provide ip or * for wildcards";
  my $reuseport = delete $opts{reuseport} || 0;
  croak "Unknown options: " . join ',', keys %opts if keys %opts;

  my $sock;
  if (($ip ne '*') || $port) {
    my ($saddr, $family) = net_gen_saddr_family($ip, $port);
    $sock = io_socket($family)->io_reuseaddr(1);
    $sock->io_reuseport($reuseport) if $reuseport;
    $sock->io_bind($saddr);
  }
  else {
    $sock = io_socket(AF_INET6)->io_reuseaddr(1);
    $sock->io_reuseport($reuseport) if $reuseport;
  }

  $sock->io_listen($backlog);
}

1;
