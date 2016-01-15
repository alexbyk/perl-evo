use Evo;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";

like exception { require MyBadComp; }, qr/MyRole.+MyBadComp.+rmethod/;

done_testing;
