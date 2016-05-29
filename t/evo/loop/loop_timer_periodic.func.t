package main;
use Evo '-Loop *; Test::More';

my $got;
loop_periodic 0, 0.00001, sub { loop_stop if ++$got > 2 };
my $id = loop_periodic 0, 0.00001, sub {fail};
loop_periodic_remove $id;

loop_start;
is $got, 3;

done_testing;
