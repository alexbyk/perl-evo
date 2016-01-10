use Evo;
use Evo::Util;
use Test::More;

sub uniq { Evo::Util::uniq(@_) }
is_deeply [uniq(1, 2, 2, 3)], [1, 2, 3];

done_testing;
