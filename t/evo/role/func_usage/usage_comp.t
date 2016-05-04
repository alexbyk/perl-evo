use Evo;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyClass;
my $obj = MyClass::new(foo => 'foo', bar => 'bar');
is $obj->foo,     'foo';
is $obj->bar,     'bar';
is $obj->foo_bar, 'foobar';
is $obj->FOO_BAR, 'FOOBAR';
is $obj->gm('V'), 'MyClassV';

is $obj->overriden1,     'OVER1';
is $obj->overriden2,     'OVER2';
is $obj->overriden3,     'OVER3';
is $obj->overriden_attr, 'OVER4';

like exception { require MyBadClass; }, qr/MyRole.+MyBadClass.+rmethod/;

done_testing;
