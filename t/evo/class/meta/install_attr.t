package main;
use Evo;
use Evo::Class::Meta;
use Test::More;
use Test::Fatal;

{

  package My::Foo;
  use Evo;
}


my $gen = {
  gs => sub {
    sub {"OK"};
  },
  new_s => sub {
    sub {'OK'}
  },
};
my $meta = Evo::Class::Meta::new(gen => $gen);

$meta->install_attr('My::Foo', 'foo', is => 'rw');

like exception {
  $meta->install_attr('My::Foo', 'foo', is => 'rw');
}, qr/My::Foo.+foo.+$0/;

use Data::Dumper;
ok $meta->data->{'My::Foo'}{bo}{known}{foo};

done_testing;
