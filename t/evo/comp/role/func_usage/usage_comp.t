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

done_testing;
