package Test::Evo::Helpers;
use Evo '-Export *';
use Evo '-Comp::Meta; Socket :all; -Role::Exporter; -Lib *; -Lib::Net *; Socket AF_INET6';

use constant CAN_BIND6 => eval {
  my ($saddr, $family) = net_gen_saddr_family('*', undef);
  socket_open_nb()->socket_bind($saddr);
};
use constant HAS_REUSEPORT => eval { socket_open_nb()->socket_reuseport; 1; };
use constant HAS_SO_DOMAIN => eval { my $v = SO_DOMAIN(); 1 };

export qw(CAN_BIND6 HAS_REUSEPORT HAS_SO_DOMAIN);

sub comp_meta : Export {
  my %gen;
  foreach my $what (qw(new gs)) {
    $gen{$what} = sub {
      sub {$what}
    };
  }

  Evo::Comp::Meta::new(gen => \%gen, rex => Evo::Role::Exporter::new());
}

1;
