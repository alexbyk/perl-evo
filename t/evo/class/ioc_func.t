package main;
use Evo;
use Test::More;
use Test::Fatal;
use Evo::Class::Gen::HUF '*';

{

  package My::Empty;
  use Evo '-Class::Out *';

  package Foo;
  use Evo '-Class::Out *';

  has 'foo', is => 'ro';
  has 'gt10', check => sub { $_[0] > 10 }, is => 'ro';
  has 'gt10rw', check => sub { $_[0] > 10 };
  has 'req', required => 1;

  has lazyv => lazy => 'LV';
  has lazyfn => lazy => sub {'LFN'};
  has with_dv => 'DV';
  has with_dfn => sub {'DFN'};
};

ok My::Empty::init([]);

my $v = 'ok';
my $obj = sub {$v};

like exception { Foo::init($obj) }, qr/req.+required.+$0/;
like exception { Foo::init($obj, gt10   => 9, req     => 1); }, qr/gt10.+$0/;
like exception { Foo::init($obj, gt10rw => 9, req     => 1); }, qr/gt10.+$0/;
like exception { Foo::init($obj, req    => 1, unknown => 1); }, qr/"unknown".+$0/;

is Foo::init($obj, gt10 => 10 + 1, foo => 'FOO', req => 1), $obj;
like exception { $obj->gt10(11); },  qr/gt10.+readonly.+$0/;
like exception { $obj->gt10rw(9); }, qr/9.+gt10.+$0/;
like exception { $obj->foo('Bad') }, qr/foo.+readonly.+$0/;

is $obj->lazyv,  'LV';
is $obj->lazyfn, 'LFN';

is $obj->gt10, 11;
is $obj->gt10rw(12)->gt10rw, 12;

is $obj->with_dv,  'DV';
is $obj->with_dfn, 'DFN';

is_deeply Evo::Class::Gen::HUF::HUF_DATA($obj),
  {req => 1, gt10 => 11, gt10rw => 12, foo => 'FOO', with_dv => 'DV', with_dfn => 'DFN',};

done_testing;
