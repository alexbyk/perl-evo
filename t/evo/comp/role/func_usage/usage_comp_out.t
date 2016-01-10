use Evo;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyCompOut;
my $obj = MyCompOut::init(sub {'hello'}, foo => 'foo', bar => 'bar');
is $obj->(), 'hello';
is $obj->foo,     'foo';
is $obj->bar,     'bar';
is $obj->foo_bar, 'foobar';
is $obj->FOO_BAR, 'FOOBAR';

like exception { require MyBadComp; }, qr/MyRole.+MyBadComp.+rmethod/;

done_testing;
