use Evo 'Test::More; Evo::Lib *';

my $arr1 = [[1, 2], [], [3]];
my $arr2 = clone_arr2 $arr1;

is_deeply $arr2, $arr1;
isnt $arr1->[0], $arr2->[0];


done_testing;
