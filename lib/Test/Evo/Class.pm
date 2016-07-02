package Test::Evo::Class;
use Evo '-Export *';

sub dummy_meta : Export {
  my $class = shift || 'My::Dummy';
  my %gen;
  foreach my $what (qw(gs gsch)) {
    $gen{$what} = sub {
      sub {$what}
    };
  }

  $gen{init} = sub ($class, $opts) {
    sub {$opts}
  };

  Evo::Class::Meta->new(gen => \%gen, class => $class);
}




1;
