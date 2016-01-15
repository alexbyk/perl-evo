use Evo;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyComp;
my $obj = MyComp::new(foo => 'foo', bar => 'bar');
is $obj->foo,     'foo';
is $obj->bar,     'bar';
is $obj->foo_bar, 'foobar';
is $obj->FOO_BAR, 'FOOBAR';
is $obj->gm('V'), 'MyCompV';

is $obj->overriden1, 'OVER1';
is $obj->overriden2, 'OVER2';
is $obj->overriden3, 'OVER3';

like exception { require MyBadComp; }, qr/MyRole.+MyBadComp.+rmethod/;

done_testing;
