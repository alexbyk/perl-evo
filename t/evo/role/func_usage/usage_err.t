use Evo;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";

like exception { require MyBadClass; }, qr/MyRole.+MyBadClass.+rmethod/;

done_testing;
