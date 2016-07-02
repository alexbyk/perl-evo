package main;
use Evo;
use Test::More;
use Evo::Internal::Exception;

{

  package My::Empty;
  use Evo '-Class *';

  package My::Foo;
  use Evo -Class, -Loaded;

  has 'foo', is => 'ro';
  has 'gt10', check => sub { $_[0] > 10 }, is => 'ro';
  has 'gt10rw', check => sub { $_[0] > 10 };
  has 'req', required => 1;

  has lazyfn => lazy => sub { 'LFN' . rand() };
  has lazyfnch => lazy => sub { 'LFNCH' . rand() }, check => sub {1};
  has with_dv => 'DV';
  has with_dfn => sub {'DFN'};

  package My::Bar;
  use Evo -Class, -Loaded;
  has 'bar';

  package My::Child;
  use Evo -Class;
  extends 'My::Foo', 'My::Bar';
  has_over 'req' => 'OVER';

  package My::Child2;
  use Evo -Class;
  with 'My::Foo', 'My::Bar';
  has_over 'req' => 'OVER';

};

# Child
for my $class (qw(My::Child My::Child2)) {
  my $child = $class->new(foo => 1, bar => 2);
  is $child->foo, 1;
  is $child->bar, 2;
  is $child->req, 'OVER';
}


ok(My::Empty->new());

my $obj = {};

like exception { My::Foo->new() }, qr/req.+required.+$0/;
like exception { My::Foo->new(gt10   => 9, req     => 1); }, qr/gt10.+$0/;
like exception { My::Foo->new(gt10rw => 9, req     => 1); }, qr/gt10.+$0/;
like exception { My::Foo->new(req    => 1, unknown => 1); }, qr/"unknown".+$0/;

$obj = My::Foo->new(gt10 => 10 + 1, foo => 'FOO', req => 1);
like exception { $obj->gt10(11); },  qr/gt10.+readonly.+$0/;
like exception { $obj->gt10rw(9); }, qr/9.+gt10.+$0/;
like exception { $obj->foo('Bad') }, qr/foo.+readonly.+$0/;

# must be called once
like $obj->lazyfn,   qr/LFN/;
is $obj->lazyfn,     $obj->lazyfn;
like $obj->lazyfnch, qr/LFNCH/;
is $obj->lazyfnch,   $obj->lazyfnch;

is $obj->gt10, 11;
is $obj->gt10rw(12)->gt10rw, 12;

is $obj->{with_dv},  'DV';
is $obj->{with_dfn}, 'DFN';
is $obj->with_dv,  'DV';
is $obj->with_dfn, 'DFN';

is_deeply $obj,
  {
  req      => 1,
  gt10     => 11,
  gt10rw   => 12,
  foo      => 'FOO',
  with_dv  => 'DV',
  with_dfn => 'DFN',
  lazyfn   => $obj->lazyfn,
  lazyfnch => $obj->lazyfnch,
  };


$obj = My::Foo::->new(req => 1, foo => 'foo');
is $obj->foo, 'foo';

done_testing;
