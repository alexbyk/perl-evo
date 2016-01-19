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
  $proto  ||= IPPROTO_TCP;
  $family ||= AF_INET6;
  my $s = gensym;
  socket($s, $family || AF_INET6, $type || SOCK_STREAM, $proto) || die "socket: $!";
  Evo::Io::Socket::init($s)->io_non_blocking(1);
  $s->io_nodelay(1) if $proto == IPPROTO_TCP;
  $s->io_v6only(1)  if $family == AF_INET6;
  $s;
}


sub io_listen(%opts) : Export {
  my $port      = delete $opts{port}      || 0;
  my $backlog   = delete $opts{backlog}   || SOMAXCONN;
  my $ip        = delete $opts{ip}        || croak "Provide ip or '0.0.0.0' or '::' for wildcards";
  my $reuseport = delete $opts{reuseport} || 0;
  croak "Unknown options: " . join ',', keys %opts if keys %opts;

  my ($saddr, $family) = net_gen_saddr_family($ip, $port);
  my $sock = io_socket($family)->io_reuseaddr(1);
  $sock->io_reuseport($reuseport) if $reuseport;
  $sock->io_bind($saddr)->io_listen($backlog);
}

1;

=head2 io_open

  my $io = io_open('>', $filename);

Open file and make it non blocking

=head2 io_open_anon

=head2 io_socket

Create a socket. Make it v6only for IPv6 and nodelay for TCP. By default AF_INET6

=head2 io_listen

Bind to port and listen. Skip port to listen on random available port. Provide '::' or '0.0.0.0' to listen all IPv6 or IPv4

  my $serv = io_listen(ip => '::', port => 8080);
  my $serv = io_listen(ip => '::', port => 8080, backlog => 10, reuseport => 1);

Pay attention that C<io_v6only> will be set for ipv6 addresses. Also C<io_reuseaddr> will be settled to true

=cut
