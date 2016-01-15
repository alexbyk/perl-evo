use Evo;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyComp;
my $obj = MyComp::new();
is $obj->a2, 'a2val';
is $obj->a1, 'a1val';

done_testing;
