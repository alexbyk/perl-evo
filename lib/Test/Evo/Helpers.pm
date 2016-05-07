package Test::Evo::Helpers;

use Evo '-Export *';
use Evo '-Class::Meta; Socket :all; -Role::Class; -Io *; -Lib::Net *; Socket AF_INET6';

use constant CAN_BIND6 => eval {
  my ($saddr, $family) = net_gen_saddr_family('::1', undef);
  io_socket()->io_bind($saddr);
};
use constant HAS_REUSEPORT => eval { io_socket()->io_reuseport; 1; };
use constant CAN_CHANGEV6ONLY => eval { !io_socket()->io_v6only(0)->io_v6only; };
use constant HAS_SO_DOMAIN    => eval { SO_DOMAIN() && 1; 1 };
use constant HAS_SO_PROTOCOL  => eval { SO_PROTOCOL() && 1; 1 };

export qw(CAN_BIND6 CAN_CHANGEV6ONLY HAS_REUSEPORT HAS_SO_DOMAIN HAS_SO_PROTOCOL);

sub comp_meta : Export {
  my %gen;
  foreach my $what (qw(new gs)) {
    $gen{$what} = sub {
      sub {$what}
    };
  }

  Evo::Class::Meta::new(gen => \%gen, rex => Evo::Role::Class::new());
}

1;
