package main;
use Evo '-Loop *';
use Test::More;

{

  package My::Mock;
  use Evo '-Comp *';
  has calls => sub { [] };
  sub timer($self, @args) { push $self->calls->@*, [@args] }
}

my $mock = My::Mock::new();
my $sub = sub { };
Evo::Loop::Comp::realm($mock, sub { loop_timer 11, $sub; });

is_deeply $mock->calls, [[11, $sub]];

done_testing;
