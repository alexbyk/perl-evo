package Evo::Net::Socket;
use Evo '-Comp::Out *; Symbol gensym';

with ':Role';

our @CARP_NOT = qw(Evo::Net::Server::Role);

sub new() { my $s = init(gensym) }

1;


=head1 SYNOPSYS

  my $sock = Evo::Net::Socket::new()->socket_open();
  $sock->socket_reuseaddr(1)->socket_listen(100);

Socket doesn't have any attached data in this role, so you can safely bless it to another package with L<Evo::Net::Socket::Role> role

=head1 METHODS

=head2  

Opens socket just like C<socket>. If already opened, dies

  my $sock = Evo::Net::Socket::new()->socket_open(AF_INET6, SOCK_STREAM, IPPROTO_TCP);

=cut


=head1 Info

  say $sock->socket_reuseaddr(1)->socket_reuseaddr;    # 1

=head2 read only

=over


=item * socket_domain 

=item * socket_type

=item * socket_protocol 

=back

=head2 read/write

=over

=item * socket_reuseaddr

=item * socket_reuseport

=item * socket_nodelay

=item * socket_nb

=back



=cut
