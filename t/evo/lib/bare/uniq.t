use Evo;
use Evo::Lib::Bare;
use Test::More;

sub uniq { Evo::Lib::Bare::uniq(@_) }
is_deeply [uniq(1, 2, 2, 3)], [1, 2, 3];

done_testing;
