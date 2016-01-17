package Test::Evo::Helpers;
use Evo '-Export *';
use Evo '-Comp::Meta; -Role::Exporter';

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
