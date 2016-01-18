package Evo::Io::Socket;
use Evo '-Comp::Out *';
with ':Role', '-Io::Handle::Role';

1;

=head1 METHODS


=head2 io_local

=head2 io_remote

  my ($ip, $port) = $sock->io_remote;
  ($ip, $port) = $sock->io_local;

More frienly results than C<getpeername> and C<getsockname> 

=head2 io_accept

Instead of saddr return a new socket and initiate with the C<init> method of the derived class


=head1 Info

  say $sock->io_reuseaddr(1)->io_reuseaddr;    # 1

=head2 read only

=over


=item * io_domain 

=item * io_type

=item * io_protocol 

=back

=head2 read/write

=over

=item * io_reuseaddr

=item * io_reuseport

=item * io_nodelay

=item * io_rcvbuf

=item * io_sndbuf

=item * non_blocking

=back



=cut
