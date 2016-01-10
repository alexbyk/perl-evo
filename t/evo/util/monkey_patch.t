package main;
use Evo -Util;
use Test::More;

{

  package Foo;

  package Bar;
  sub foo {'foo'}

}

my %hash = (foo => sub {'pfoo'}, bar => sub {'pbar'});

Evo::Util::monkey_patch('Foo', %hash);
is Foo::foo(), 'pfoo';
is Foo::bar(), 'pbar';

my $restore = Evo::Util::monkey_patch_silent('Bar', foo => sub {'pfoo'}, bar => sub {'pbar'});
is Bar::foo(), 'pfoo';
is Bar::bar(), 'pbar';

is $restore->{foo}->(), 'foo';
ok exists $restore->{bar};
ok !$restore->{bar};

delete $restore->{bar};
Evo::Util::monkey_patch_silent('Bar', %$restore);
is Bar::foo(), 'foo';

done_testing;
