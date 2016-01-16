package main;
use Evo '-Loop *; Test::More';

my $got;
loop_timer 0, 0.00001, sub { loop_stop if ++$got > 2 };

loop_start;
is $got, 3;

done_testing;
