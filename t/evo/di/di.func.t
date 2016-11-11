package main;
use Evo 'Test::More; Evo::Di; Evo::Internal::Exception';

{

  package My::Alien;
  use Evo -Loaded;
  sub new { bless {}, __PACKAGE__ }

  package My::C1;
  use Evo -Class, -Loaded;
  has c2 => inject 'My::C2';
  has not_required => optional, inject 'My::Missing';

  package My::C2;
  use Evo -Class, -Loaded;
  has 'c3'  => inject 'My::C3';
  has alien => inject 'My::Alien';

  package My::C3;
  use Evo -Class, -Loaded;
  has val => inject 'My::C3/val';

  package My::Fail;
  use Evo -Class, -Loaded;
  has missing => inject 'My::Missing',;

  package My::Circ1;
  use Evo -Class, -Loaded;
  has circ2 => inject 'My::Circ2',;

  package My::Circ2;
  use Evo -Class, -Loaded;
  has circ3 => inject 'My::Circ3',;

  package My::Circ3;
  use Evo -Class, -Loaded;
  has circ1 => inject 'My::Circ1',;
}

EXISTING: {
  my $di = Evo::Di->new();
  $di->provide('SOME_CONSTANT' => 33);
  is $di->single('SOME_CONSTANT'), 33;
}

PROVIDE: {
  my $di = Evo::Di->new;
  $di->provide(foo => 'FOO', bar => 'BAR');
  is $di->single('foo'), 'FOO';
  is $di->single('bar'), 'BAR';
  like exception { $di->provide('foo', 33) }, qr/"foo".+$0/;
}

OK: {
  my $di = Evo::Di->new;
  $di->provide('My::C3/val', 'V');
  my $c1 = $di->single('My::C1');
  is $c1, $di->single('My::C1');
  ok !exists $c1->{not_required};
  is $c1->c2, $di->single('My::C2');
  is $c1->c2->alien, $di->single('My::Alien');
  is $c1->c2->c3,    $di->single('My::C3');
  is $c1->c2->c3->val, $di->single('My::C3/val');
}

FAIL: {
  my $di = Evo::Di->new;
  like exception { $di->single('My::Fail'); }, qr/My::Missing.+My::Fail.+$0/;
}

CIRC: {
  my $di = Evo::Di->new;
  like exception { $di->single('My::Circ1') },
    qr/My::Circ1 -> My::Circ2 -> My::Circ3 -> My::Circ1.+$0/;
}

done_testing;
