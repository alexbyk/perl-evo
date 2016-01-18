package Test::Evo::Helpers;
use Evo '-Export *';
use Evo '-Comp::Meta; -Role::Exporter; -Lib *; -Lib::Net *; Socket AF_INET6';

use constant HAS_IPV6 => eval {
  my ($saddr, $family) = net_gen_saddr_family('*', undef);
  socket_open()->socket_bind($saddr);
};
use constant HAS_REUSEPORT => eval {
  socket_open()->socket_reuseport;
  1;
};

export qw(HAS_IPV6 HAS_REUSEPORT);

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
