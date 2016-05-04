package main;
use Evo;
use Test::More;
use Test::Fatal;
use Evo::Role::Exporter;

{

  package My::Role1;
  use Evo;
  sub m1 {'M1'}

  package My::Role2;
  use Evo;
  sub m2 {'M2'}

}

my $obj = Evo::Role::Exporter::new();

no warnings 'redefine';
my $loaded;
local *Evo::Role::Exporter::load = sub { $loaded++ };

$obj->add_methods('My::Role1', 'm1');
$obj->add_attr('My::Role1', 'a1', is => 'rw');
$obj->hooks('My::Role1', 'h1');

$obj->add_methods('My::Role2', 'm2');
$obj->add_attr('My::Role2', 'a2', is => 'ro');
$obj->hooks('My::Role2', 'h2');

my $meth;
$obj->add_gen(
  'My::Role3',
  'gm3' => sub {
    my $class = shift;
    $meth = sub {$class}
  }
);

$obj->proxy('My::Proxy', 'My::Role1');
$obj->proxy('My::Proxy', 'My::Role2');
$obj->proxy('My::Proxy', 'My::Role3');
is $loaded, 3;

is_deeply { $obj->methods('My::Proxy', 'MyClass') },
  {m1 => *My::Role1::m1{CODE}, m2 => *My::Role2::m2{CODE}, gm3 => $meth};

is_deeply { $obj->attrs('My::Proxy') }, {a1 => [is => 'rw'], a2 => [is => 'ro']};

is_deeply [$obj->hooks('My::Proxy')], ['h1', 'h2'];

like exception {
  $obj->proxy('My::Proxy', 'My::Role2');
}, qr/clashes/;

done_testing;
