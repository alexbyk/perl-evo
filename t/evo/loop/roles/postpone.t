package main;
use Evo -Loop::Comp;
use Test::More;

my $zc;
{

  package MyLoop;
  use Evo '-Comp *', -Loaded;
  with 'Evo::Loop::Role::Postpone';

  sub zone_cb { $zc++; $_[1] }
}

my $loop = MyLoop::new();

is $loop->postpone_count, 0;

my @order;
$loop->postpone(
  sub {
    push @order, 1;
    $loop->postpone(sub { push @order, 3 });
  }
);
$loop->postpone(sub { push @order, 2; });
is $loop->postpone_count, 2;
is $zc, 2;

$loop->postpone_process;
is $loop->postpone_count, 0;
is $zc, 3;

is_deeply \@order, [1, 2, 3];

done_testing;
